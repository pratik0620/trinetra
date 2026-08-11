import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/relay_packet.dart';

enum RelayState {
  idle,
  advertising,
  scanning,
  nearbyEmergencyDetected,
}

abstract class RelayService {
  Future<bool> startAdvertising(RelayPacket packet);
  Future<void> stopAdvertising();
  Future<void> startScanning();
  Future<void> stopScanning();
  
  Stream<RelayPacket> get packetStream;
  Stream<RelayState> get stateStream;
  RelayState get currentState;
  
  Future<bool> checkPermissions();
  Future<bool> isBluetoothOn();
}

class RelayServiceImpl implements RelayService {
  final _packetController = StreamController<RelayPacket>.broadcast();
  final _stateController = StreamController<RelayState>.broadcast();
  RelayState _currentState = RelayState.idle;
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  Timer? _scanTimer;
  bool _isScanTimerActive = false;
  
  static const String relayServiceUuid = 'd3b7d2e0-2b1d-4b8f-a1d2-0c9f1a2b3c4d';
  static const _channel = MethodChannel('com.example.women_safety_app/relay');

  // Keep track of processed packet device IDs to prevent duplicates within 15 seconds.
  final Map<String, DateTime> _seenPackets = {};
  
  RelayServiceImpl() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
          if (state != BluetoothAdapterState.on) {
            debugPrint('[RELAY] Bluetooth adapter turned off.');
            stopAdvertising();
            stopScanning();
          }
        }, onError: (e) {
          debugPrint('[RELAY] Error in BLE adapter state listener: $e');
        });
      } catch (e) {
        debugPrint('[RELAY] Warning: Bluetooth adapter state stream is unavailable: $e');
      }
    } else {
      debugPrint('[RELAY] Skipping BLE adapter state subscription on unsupported platform.');
    }
  }

  @override
  Stream<RelayPacket> get packetStream => _packetController.stream;

  @override
  Stream<RelayState> get stateStream => _stateController.stream;

  @override
  RelayState get currentState => _currentState;

  void _updateState(RelayState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('[RELAY] State changed to: $newState');
    }
  }

  bool _isDuplicate(RelayPacket packet) {
    final now = DateTime.now();
    final lastSeen = _seenPackets[packet.deviceId];
    if (lastSeen != null && now.difference(lastSeen).inSeconds < 15) {
      return true;
    }
    _seenPackets[packet.deviceId] = now;
    return false;
  }

  @override
  Future<bool> startAdvertising(RelayPacket packet) async {
    final permissionsGranted = await checkPermissions();
    if (!permissionsGranted) {
      debugPrint('[RELAY] Permissions not granted for advertising.');
      return false;
    }
    
    final btOn = await isBluetoothOn();
    if (!btOn) {
      debugPrint('[RELAY] Bluetooth is off, cannot advertise.');
      return false;
    }
    
    _updateState(RelayState.advertising);
    final payload = packet.toCsv();
    debugPrint('[RELAY] Starting advertising with payload: $payload');
    
    try {
      final success = await _channel.invokeMethod<bool>('startAdvertising', {
        'serviceUuid': relayServiceUuid,
        'payload': payload,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[RELAY] Platform startAdvertising error: $e');
      _updateState(RelayState.idle);
      return false;
    }
  }

  @override
  Future<void> stopAdvertising() async {
    if (_currentState == RelayState.advertising) {
      try {
        await _channel.invokeMethod('stopAdvertising');
      } catch (e) {
        debugPrint('[RELAY] Platform stopAdvertising error: $e');
      }
      _updateState(RelayState.idle);
      debugPrint('[RELAY] Stopped advertising.');
    }
  }

  @override
  Future<void> startScanning() async {
    if (_currentState == RelayState.scanning || _currentState == RelayState.nearbyEmergencyDetected) {
      return;
    }
    
    final permissionsGranted = await checkPermissions();
    if (!permissionsGranted) {
      debugPrint('[RELAY] Permissions not granted for scanning.');
      return;
    }
    
    final btOn = await isBluetoothOn();
    if (!btOn) {
      debugPrint('[RELAY] Bluetooth is off, cannot scan.');
      return;
    }
    
    _updateState(RelayState.scanning);
    debugPrint('[RELAY] Starting periodic scan...');
    
    _isScanTimerActive = true;
    _runPeriodicScanCycle();
  }

  /// Implements adaptive/periodic scanning:
  /// Scans for 3 seconds, then idles for 7 seconds. Repeats until stopped.
  void _runPeriodicScanCycle() async {
    if (!_isScanTimerActive) return;
    
    debugPrint('[RELAY] Scan Cycle: Scanning for 3 seconds...');
    
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final manufacturerData = result.advertisementData.manufacturerData;
        if (manufacturerData.containsKey(65535)) {
          final bytes = manufacturerData[65535]!;
          try {
            final csvString = utf8.decode(bytes);
            debugPrint('[RELAY] Found relay advertisement raw: $csvString');
            
            final packet = RelayPacket.fromCsv(csvString);
            if (!_isDuplicate(packet)) {
              _packetController.add(packet);
              
              // Switch to active scanning (longer scan window) temporarily for 30 seconds
              _triggerTemporaryActiveScan();
            } else {
              debugPrint('[RELAY] Duplicate packet ignored: ${packet.deviceId}');
            }
          } catch (e) {
            debugPrint('[RELAY] Error decoding or parsing packet: $e');
          }
        }
      }
    }, onError: (e) {
      debugPrint('[RELAY] Scan error in listener: $e');
    });

    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        withServices: [Guid(relayServiceUuid)],
        timeout: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('[RELAY] Error starting scan: $e');
    }

    // Schedule next scan in 10 seconds (7 seconds idle)
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 10), () {
      if (_currentState == RelayState.scanning) {
        _runPeriodicScanCycle();
      }
    });
  }

  /// Temporarily switches scanning behavior to continuous active scanning for 30 seconds
  void _triggerTemporaryActiveScan() async {
    debugPrint('[RELAY] ⚠️ Relay beacon detected! Switching to active scanning for 30s...');
    _updateState(RelayState.nearbyEmergencyDetected);
    
    _scanTimer?.cancel();
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final manufacturerData = result.advertisementData.manufacturerData;
        if (manufacturerData.containsKey(65535)) {
          final bytes = manufacturerData[65535]!;
          try {
            final csvString = utf8.decode(bytes);
            final packet = RelayPacket.fromCsv(csvString);
            if (!_isDuplicate(packet)) {
              _packetController.add(packet);
            }
          } catch (_) {}
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(relayServiceUuid)],
        timeout: const Duration(seconds: 30),
      );
    } catch (_) {}

    // After 30 seconds, resume standard periodic scanning
    _scanTimer = Timer(const Duration(seconds: 30), () {
      if (_isScanTimerActive) {
        _updateState(RelayState.scanning);
        _runPeriodicScanCycle();
      } else {
        _updateState(RelayState.idle);
      }
    });
  }

  @override
  Future<void> stopScanning() async {
    _isScanTimerActive = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('[RELAY] stopScan failed: $e');
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _updateState(RelayState.idle);
    debugPrint('[RELAY] Stopped scanning.');
  }

  @override
  Future<bool> checkPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();
      
      return statuses[Permission.bluetoothScan]?.isGranted == true &&
          statuses[Permission.bluetoothConnect]?.isGranted == true &&
          statuses[Permission.bluetoothAdvertise]?.isGranted == true &&
          statuses[Permission.location]?.isGranted == true;
    }
    return true;
  }

  @override
  Future<bool> isBluetoothOn() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return false;
    }
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[RELAY] isBluetoothOn failed: $e');
      return false;
    }
  }
}
