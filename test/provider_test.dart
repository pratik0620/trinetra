import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:women_safety_app/core/models/sensor_data.dart';
import 'package:women_safety_app/core/services/ble_service.dart';
import 'package:women_safety_app/providers/app_providers.dart';
import 'package:women_safety_app/providers/ble_state_provider.dart';
import 'package:women_safety_app/providers/sensor_selectors.dart';
import 'package:women_safety_app/providers/mock_state_provider.dart';
import 'package:women_safety_app/models/app_models.dart';

class FakeBleService implements BleService {
  final _sensorController = StreamController<SensorData>.broadcast();
  final _connectionController = StreamController<BleConnectionState>.broadcast();
  BleConnectionState _connectionState = BleConnectionState.disconnected;

  @override
  Stream<SensorData> get sensorStream => _sensorController.stream;

  @override
  Stream<BleConnectionState> get connectionStream => _connectionController.stream;

  @override
  BleConnectionState get currentConnectionState => _connectionState;

  @override
  bool get isBluetoothOff => false;

  void emitSensorData(SensorData data) {
    _sensorController.add(data);
  }

  void emitConnectionState(BleConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }

  @override
  void dispose() {
    _sensorController.close();
    _connectionController.close();
  }

  @override
  Future<void> startScan() async {}

  @override
  Future<void> connect(fbp.BluetoothDevice device) async {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  late FakeBleService fakeBleService;
  late ProviderContainer container;

  setUp(() {
    fakeBleService = FakeBleService();
    container = ProviderContainer(
      overrides: [
        bleServiceProvider.overrideWithValue(fakeBleService),
      ],
    );
    // Eagerly read to register stream listeners
    container.read(bleStateProvider);
  });

  tearDown(() {
    container.dispose();
    fakeBleService.dispose();
  });

  group('Milestone 2 Provider Integration Tests', () {
    test('Initial State', () {
      final bleState = container.read(bleStateProvider);
      expect(bleState.connectionState, BleConnectionState.disconnected);
      expect(bleState.sensorData, isNull);
      expect(bleState.lastUpdate, isNull);
      expect(bleState.isLive, isFalse);
    });

    test('Packet update triggers live data and updates timestamps', () async {
      // Set state to connected
      fakeBleService.emitConnectionState(BleConnectionState.connected);
      
      // Wait for stream event to propagate
      await Future.delayed(Duration.zero);

      final sensorPacket = SensorData(
        state: 'NORMAL',
        battery: 87,
        timestamp: DateTime.now(),
      );

      fakeBleService.emitSensorData(sensorPacket);
      await Future.delayed(Duration.zero);

      final bleState = container.read(bleStateProvider);
      expect(bleState.connectionState, BleConnectionState.connected);
      expect(bleState.sensorData?.battery, 87);
      expect(bleState.sensorData?.state, 'NORMAL');
      expect(bleState.lastUpdate, isNotNull);
      expect(bleState.isLive, isTrue);
      expect(bleState.packetCount, 1);

      // Emit second packet and verify packetCount increments to 2
      final secondPacket = SensorData(
        state: 'NORMAL',
        battery: 86,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(secondPacket);
      await Future.delayed(Duration.zero);
      expect(container.read(bleStateProvider).packetCount, 2);

      // Verify effectiveSensorProvider returns the live packet
      final effectiveSensor = container.read(effectiveSensorProvider);
      expect(effectiveSensor?.battery, 86);

      // Verify effectiveSafetyStatusProvider maps NORMAL to safe
      final safetyStatus = container.read(effectiveSafetyStatusProvider);
      expect(safetyStatus, SafetyStatusEnum.safe);

      // Verify effectiveShoeStatusProvider maps to live status model
      final shoeStatus = container.read(effectiveShoeStatusProvider);
      expect(shoeStatus.isConnected, isTrue);
      expect(shoeStatus.batteryPercent, 86);
    });

    test('Disconnect retains last sensor values and sets isLive false', () async {
      // 1. Establish connection and receive data
      fakeBleService.emitConnectionState(BleConnectionState.connected);
      await Future.delayed(Duration.zero);

      final sensorPacket = SensorData(
        state: 'NORMAL',
        battery: 92,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(sensorPacket);
      await Future.delayed(Duration.zero);

      // 2. Disconnect the BLE Service
      fakeBleService.emitConnectionState(BleConnectionState.disconnected);
      await Future.delayed(Duration.zero);

      final bleState = container.read(bleStateProvider);
      expect(bleState.connectionState, BleConnectionState.disconnected);
      expect(bleState.isLive, isFalse);
      
      // Retains the last packet values in bleState Provider
      expect(bleState.sensorData?.battery, 92);

      // Verify fallback to mock state for effective providers
      final mockState = container.read(mockStateProvider);
      final effectiveShoe = container.read(effectiveShoeStatusProvider);
      
      // Since isLive is false, it returns the mock state shoeStatus
      expect(effectiveShoe.batteryPercent, mockState.shoeStatus.batteryPercent);
      expect(effectiveShoe.isConnected, mockState.shoeStatus.isConnected);
    });

    test('Reconnect restores live updates', () async {
      // 1. Initially disconnected, fallback is mock
      final mockState = container.read(mockStateProvider);
      expect(container.read(effectiveShoeStatusProvider).batteryPercent, mockState.shoeStatus.batteryPercent);

      // 2. Connect and emit data
      fakeBleService.emitConnectionState(BleConnectionState.connected);
      await Future.delayed(Duration.zero);

      final sensorPacket = SensorData(
        state: 'NORMAL',
        battery: 75,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(sensorPacket);
      await Future.delayed(Duration.zero);

      // 3. Verify live values replace mocked values
      expect(container.read(effectiveShoeStatusProvider).batteryPercent, 75);
    });

    test('Mock Fallback returns mock sensor data when disconnected', () {
      final mockState = container.read(mockStateProvider);
      final effectiveSensor = container.read(effectiveSensorProvider);

      expect(effectiveSensor, isNotNull);
      expect(effectiveSensor?.battery, mockState.shoeStatus.batteryPercent);
      expect(effectiveSensor?.gpsFresh, mockState.shoeStatus.isGpsAvailable);
      expect(effectiveSensor?.state, mockState.safetyStatus == SafetyStatusEnum.emergency ? 'EMERGENCY' : 'NORMAL');
    });

    test('Emergency packet triggers SafetyStatusEnum.emergency', () async {
      fakeBleService.emitConnectionState(BleConnectionState.connected);
      await Future.delayed(Duration.zero);

      final sensorPacket = SensorData(
        state: 'EMERGENCY',
        lat: 12.34,
        lon: 56.78,
        gpsFresh: true,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(sensorPacket);
      await Future.delayed(Duration.zero);

      final safetyStatus = container.read(effectiveSafetyStatusProvider);
      expect(safetyStatus, SafetyStatusEnum.emergency);
    });
  });
}
