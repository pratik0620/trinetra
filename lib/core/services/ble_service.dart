import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sensor_data.dart';

enum BleConnectionState { disconnected, scanning, connecting, connected }

class BleService {
  final _sensorController = StreamController<SensorData>.broadcast();
  final _connectionController = StreamController<BleConnectionState>.broadcast();

  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BluetoothDevice? _connectedDevice;

  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  bool _isUserDisconnected = false;
  bool _isBluetoothOff = false;
  bool _isReconnecting = false;
  bool _isFirstPacketReceived = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  BleService() {
    debugPrint('[BLE] Service initialized');
    // Listen to the Bluetooth adapter state at the OS level
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _isBluetoothOff = false;
      } else {
        _isBluetoothOff = true;
        debugPrint('[BLE] Bluetooth adapter state turned off.');
        _handleBluetoothOff();
      }
    });
  }

  Stream<SensorData> get sensorStream => _sensorController.stream;
  Stream<BleConnectionState> get connectionStream => _connectionController.stream;

  // Helper getters
  bool get isBluetoothOff => _isBluetoothOff;
  BleConnectionState get currentConnectionState => _connectionState;

  void _updateConnectionState(BleConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionController.add(newState);
      debugPrint('[BLE] Connection state transitioned to: $newState');
    }
  }

  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final locationGranted = statuses[Permission.location]?.isGranted ?? false;

      return scanGranted && connectGranted && locationGranted;
    }
    return true;
  }

  Future<void> startScan() async {
    if (_connectionState == BleConnectionState.scanning ||
        _connectionState == BleConnectionState.connected ||
        _connectionState == BleConnectionState.connecting) {
      return;
    }

    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      debugPrint('[BLE] Runtime permissions not granted.');
      _updateConnectionState(BleConnectionState.disconnected);
      return;
    }

    if (_isBluetoothOff) {
      debugPrint('[BLE] Cannot scan because Bluetooth is off.');
      _updateConnectionState(BleConnectionState.disconnected);
      return;
    }

    if (_connectionState == BleConnectionState.scanning ||
        _connectionState == BleConnectionState.connecting) {
      debugPrint('[BLE] Already scanning or connecting.');
      return;
    }

    _isUserDisconnected = false;
    _updateConnectionState(BleConnectionState.scanning);
    debugPrint('[BLE] Scanning...');

    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();

    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (var result in results) {
          debugPrint('[BLE] Device: ${result.device.platformName}');
          debugPrint('[BLE] Adv Name: ${result.advertisementData.advName}');
          debugPrint('[BLE] Remote ID: ${result.device.remoteId}');
          debugPrint('[BLE] Service UUIDs: ${result.advertisementData.serviceUuids}');

          final advName = result.advertisementData.advName;
          final platformName = result.device.platformName;

          if (advName == 'RAKSHA_SHOE' || platformName == 'RAKSHA_SHOE') {
            debugPrint('[BLE] Found RAKSHA_SHOE');
            debugPrint('[BLE] Found RAKSHA_SHOE. Stopping scan and connecting...');
            FlutterBluePlus.stopScan();
            connect(result.device);
            break;
          }
        }
      },
      onError: (e) {
        debugPrint('[BLE] Scan error: $e');
        _updateConnectionState(BleConnectionState.disconnected);
      },
    );

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('[BLE] Failed to start scan: $e');
      _updateConnectionState(BleConnectionState.disconnected);
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (_isBluetoothOff) {
      debugPrint('[BLE] Cannot connect because Bluetooth is off.');
      _updateConnectionState(BleConnectionState.disconnected);
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
    _isFirstPacketReceived = false;
    _isConnecting = true;
    _isConnected = false;

    debugPrint('[BLE] Connecting...');
    _updateConnectionState(BleConnectionState.connecting);

    await _cleanupConnection();
    _connectedDevice = device;

    _deviceStateSubscription = device.connectionState.listen(
      (state) {
        debugPrint('[BLE] Connection state: $state');
        if (state == BluetoothConnectionState.disconnected) {
          if (_isConnecting) {
            debugPrint('[BLE] Ignoring disconnect during connection setup');
            return;
          }
          _handleDisconnected();
        }
      },
      onError: (e, stackTrace) {
        debugPrint('[BLE] Device state stream error: $e');
        if (_isConnecting) {
          debugPrint('[BLE] Ignoring disconnect stream error during connection setup');
          return;
        }
        _handleDisconnected(error: e, stackTrace: stackTrace);
      },
    );

    try {
      await FlutterBluePlus.stopScan();
      await device.connect(timeout: const Duration(seconds: 10));
      debugPrint('[BLE] Connected');

      try {
        await device.requestMtu(247);
        debugPrint('[BLE] MTU negotiated');
      } catch (_) {
        debugPrint('[BLE] MTU request skipped');
      }

      final services = await device.discoverServices();
      debugPrint('[BLE] Services discovered: ${services.length}');

      for (final service in services) {
        debugPrint('[BLE] Service: ${service.uuid}');
        for (final c in service.characteristics) {
          debugPrint(
            '[BLE] Characteristic: ${c.uuid} notify=${c.properties.notify}',
          );
        }
      }

      const String targetServiceUuidStr = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
      const String notifyCharUuidStr = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

      BluetoothService? targetService;
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == targetServiceUuidStr) {
          targetService = s;
          break;
        }
      }

      if (targetService == null) {
        debugPrint('[BLE] Notify characteristic missing (service not found)');
        _updateConnectionState(BleConnectionState.disconnected);
        _isConnecting = false;
        return;
      }

      BluetoothCharacteristic? targetChar;
      for (var c in targetService.characteristics) {
        if (c.uuid.toString().toLowerCase() == notifyCharUuidStr) {
          targetChar = c;
          break;
        }
      }

      if (targetChar == null) {
        debugPrint('[BLE] Notify characteristic missing (characteristic not found)');
        _updateConnectionState(BleConnectionState.disconnected);
        _isConnecting = false;
        return;
      }

      debugPrint('[BLE] Notify characteristic found');
      debugPrint('[BLE] Notify characteristic UUID: ${targetChar.uuid}');

      debugPrint('[BLE] Found notify characteristic. Enabling notifications...');
      await targetChar.setNotifyValue(true);
      debugPrint('[BLE] Notifications enabled');

      await _notifySubscription?.cancel();
      debugPrint('[BLE] Subscription started');
      _notifySubscription = targetChar.lastValueStream.listen(
        (value) {
          if (!_isFirstPacketReceived) {
            _isFirstPacketReceived = true;
            debugPrint('[BLE] First packet received');
          }
          debugPrint('[BLE] Raw packet received: $value');
          _onCharacteristicValueReceived(value);
        },
        onError: (e, stackTrace) {
          debugPrint('[BLE] Notify error: $e');
          debugPrint('$stackTrace');
        },
        onDone: () {
          debugPrint('[BLE] Notify stream closed');
        },
      );

      _isConnecting = false;
      _isConnected = true;
      _updateConnectionState(BleConnectionState.connected);
    } catch (e, stackTrace) {
      _isConnecting = false;
      _isConnected = false;
      debugPrint('[BLE] Connection error: $e');
      debugPrint('$stackTrace');
      _handleDisconnected(error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _isUserDisconnected = true;
    _isConnected = false;
    _isConnecting = false;
    _updateConnectionState(BleConnectionState.disconnected);
    await _cleanupConnection();
  }

  Future<void> _cleanupConnection() async {
    _isConnected = false;
    _isConnecting = false;
    await _notifySubscription?.cancel();
    _notifySubscription = null;

    await _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        debugPrint('[BLE] Disconnect error: $e');
      }
      _connectedDevice = null;
    }
  }

  void _handleBluetoothOff() {
    FlutterBluePlus.stopScan();
    _cleanupConnection();
    _updateConnectionState(BleConnectionState.disconnected);
  }

  void _handleDisconnected({Object? error, StackTrace? stackTrace}) {
    _isConnected = false;
    _isConnecting = false;
    final prevState = _connectionState;
    debugPrint('[BLE] Disconnected event triggered.');
    debugPrint('[BLE] Previous connection state: $prevState');
    if (error != null) {
      debugPrint('[BLE] Disconnection/connection error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[BLE] Disconnection/connection stack trace: $stackTrace');
    }
    if (_connectedDevice != null) {
      final code = _connectedDevice!.disconnectReason?.code;
      final description = _connectedDevice!.disconnectReason?.description;
      debugPrint('[BLE] Disconnect reason: code=$code, description=$description');
    }

    _cleanupConnection();

    final willReconnect = !(_isUserDisconnected || _isBluetoothOff);
    debugPrint('[BLE] Reconnect scheduled: $willReconnect');

    if (_isUserDisconnected || _isBluetoothOff) {
      _updateConnectionState(BleConnectionState.disconnected);
      return;
    }

    _updateConnectionState(BleConnectionState.disconnected);
    _scheduleReconnection();
  }

  void _scheduleReconnection() {
    if (_isReconnecting) return;
    _isReconnecting = true;

    debugPrint('[BLE] Unexpectedly disconnected. Retrying in 2 seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () async {
      _isReconnecting = false;
      if (_isUserDisconnected || _isBluetoothOff) return;
      if (_isConnected || _isConnecting) return;

      debugPrint('[BLE] Auto-reconnecting: scanning for RAKSHA_SHOE.');
      await startScan();
    });
  }

  void _onCharacteristicValueReceived(List<int> value) {
    if (value.isEmpty) return;

    if (value.length > 128) {
      debugPrint('[BLE] Ignoring malformed or oversized packet');
      return;
    }

    String decodedString;
    try {
      decodedString = utf8.decode(value);
    } catch (e) {
      debugPrint('[BLE] Ignoring malformed or oversized packet');
      return;
    }

    if (decodedString.length > 128) {
      debugPrint('[BLE] Ignoring malformed or oversized packet');
      return;
    }

    try {
      final json = jsonDecode(decodedString);
      if (json is Map<String, dynamic>) {
        final sensorData = SensorData.fromJson(json);
        _sensorController.add(sensorData);

        // Required console logging for Milestone 1
        print('[BLE] Raw JSON: $decodedString');
        print('[BLE] Parsed SensorData: state=${sensorData.state}, fsr=${sensorData.fsr}, '
            'accel=${sensorData.accel}, gyro=${sensorData.gyro}, lat=${sensorData.lat}, '
            'lon=${sensorData.lon}, battery=${sensorData.battery}, gpsFresh=${sensorData.gpsFresh}, '
            'timestamp=${sensorData.timestamp}');
        debugPrint('[BLE] Parsed packet: state=${sensorData.state}, fsr=${sensorData.fsr}, '
            'accel=${sensorData.accel}, gyro=${sensorData.gyro}, lat=${sensorData.lat}, '
            'lon=${sensorData.lon}, battery=${sensorData.battery}, gpsFresh=${sensorData.gpsFresh}, '
            'timestamp=${sensorData.timestamp}');
      } else {
        debugPrint('[BLE] Ignoring malformed or oversized packet');
      }
    } catch (e) {
      debugPrint('[BLE] Ignoring malformed or oversized packet');
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _adapterSubscription?.cancel();
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _deviceStateSubscription?.cancel();
    _sensorController.close();
    _connectionController.close();
  }
}
