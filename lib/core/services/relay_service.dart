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
  StreamSubscription<bool>? _isScanningSubscription;
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
    
    // Check permission status for individual logging
    final advGranted = await Permission.bluetoothAdvertise.isGranted;
    
    debugPrint('[Relay] Starting advertising');
    debugPrint('[Relay] Bluetooth enabled: $btOn');
    debugPrint('[Relay] Advertiser available: true');
    debugPrint('[Relay] Advertise permission: ${advGranted ? "granted" : "denied"}');
    debugPrint('[Relay] Service UUID: $relayServiceUuid');
    debugPrint('[Relay] Payload length: ${payload.length}');
    debugPrint('[Relay] Calling BluetoothLeAdvertiser.startAdvertising()');
    debugPrint('[Relay] MethodChannel startAdvertising invoked');
    
    try {
      final success = await _channel.invokeMethod<bool>('startAdvertising', {
        'serviceUuid': relayServiceUuid,
        'payload': payload,
      });
      
      if (success == true) {
        debugPrint('[Relay] Native advertiser returned success');
        debugPrint('[Relay] Advertising started successfully');
      } else {
        debugPrint('[Relay] Native advertiser returned error');
        debugPrint('[Relay] Advertising failed');
      }
      
      return success ?? false;
    } catch (e) {
      debugPrint('[Relay] Native advertiser returned error: $e');
      debugPrint('[Relay] Advertising failed');
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

  Future<void> _startScanIfPossible() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    
    // Check if scan is already active in flutter_blue_plus
    try {
      if (!FlutterBluePlus.isScanningNow) {
        debugPrint('[RELAY] No active BLE scan detected. Initiating background scan...');
        await FlutterBluePlus.startScan(
          timeout: const Duration(minutes: 5),
        );
      } else {
        debugPrint('[RELAY] BLE scan is already active. Subscribing to scanResults.');
      }
    } catch (e) {
      debugPrint('[RELAY] startScan failed: $e');
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
    _isScanTimerActive = true;
    
    // 1. Subscribe to global scan results stream
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final manufacturerData = result.advertisementData.manufacturerData;
        if (manufacturerData.containsKey(65535)) {
          final bytes = manufacturerData[65535]!;
          try {
            final csvString = utf8.decode(bytes);
            debugPrint('[RELAY] Found relay advertisement: $csvString');
            
            final packet = RelayPacket.fromCsv(csvString);
            if (!_isDuplicate(packet)) {
              _packetController.add(packet);
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

    // 2. Subscribe to scan state changes to auto-restart scan if stopped externally
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      _isScanningSubscription?.cancel();
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && _currentState == RelayState.scanning && _isScanTimerActive) {
          debugPrint('[RELAY] Scan stopped externally. Restarting...');
          _startScanIfPossible();
        }
      });
    }

    // 3. Trigger scanning
    await _startScanIfPossible();
  }

  void _triggerTemporaryActiveScan() {
    debugPrint('[RELAY] ⚠️ Relay beacon detected! Transitioning state to nearbyEmergencyDetected.');
    _updateState(RelayState.nearbyEmergencyDetected);
    
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 30), () {
      if (_isScanTimerActive) {
        _updateState(RelayState.scanning);
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
    
    _isScanningSubscription?.cancel();
    _isScanningSubscription = null;
    
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    
    _updateState(RelayState.idle);
    debugPrint('[RELAY] Stopped scanning (subscription removed, left scan active).');
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
