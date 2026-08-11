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
import 'package:women_safety_app/models/emergency_model.dart';
import 'package:women_safety_app/models/safety_event_model.dart';
import 'package:women_safety_app/models/user_model.dart';
import 'package:women_safety_app/services/auth_service.dart';
import 'package:women_safety_app/repositories/auth_repository.dart';
import 'package:women_safety_app/repositories/emergency_repository.dart';
import 'package:women_safety_app/models/offline_emergency_model.dart';
import 'package:women_safety_app/models/emergency_location_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

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

class FakeEmergencyRepository implements EmergencyRepository {
  int createEmergencyCount = 0;
  String? lastTriggerType;
  double? lastLat;
  double? lastLon;

  @override
  Future<String> createEmergency({
    required String userId,
    required String deviceId,
    required String triggerType,
    double? latitude,
    double? longitude,
    bool isFallback = false,
    double accuracy = 5.0,
  }) async {
    createEmergencyCount++;
    lastTriggerType = triggerType;
    lastLat = latitude;
    lastLon = longitude;
    return 'fake_emergency_id_123';
  }

  @override
  Future<void> respondToEmergency({
    required String emergencyId,
    required String guardianUid,
  }) async {}

  @override
  Future<void> resolveEmergency(String emergencyId) async {}

  @override
  Future<void> cancelEmergency(String emergencyId) async {}

  @override
  Stream<EmergencyModel?> streamEmergency(String emergencyId) => Stream.value(null);

  @override
  Stream<EmergencyModel?> streamActiveEmergencyForUser(String userId) => Stream.value(null);

  @override
  Stream<List<SafetyEventFirestoreModel>> streamSafetyHistory(String userId) => Stream.value([]);

  @override
  void registerOfflineEmergency(OfflineEmergencyModel model) {}

  @override
  Stream<OfflineEmergencyModel?> streamUnifiedEmergency(String emergencyId) => Stream.value(null);

  @override
  Future<void> syncPendingEmergencyUpdates() async {}

  @override
  Future<void> updateUserEmergencyLocation({
    required String emergencyId,
    required String userId,
    required String name,
    required String role,
    required double latitude,
    required double longitude,
    bool isFallback = false,
  }) async {}

  @override
  Stream<List<EmergencyLocationModel>> streamEmergencyLocations(String emergencyId) => Stream.value([]);
}

class FakeAuthService implements AuthService {
  @override
  String normalizePhoneNumber(String rawPhone) => rawPhone;

  @override
  Future<String?> getLocalSessionUid() async => 'fake_user_uid';
  
  @override
  Future<String?> getLocalSessionPhone() async => '+919876543210';
  
  @override
  Future<void> saveLocalSession({required String phone, required String uid}) async {}

  @override
  Future<void> clearLocalSession() async {}

  @override
  Future<UserModel?> findUserByPhone(String phone) async => null;

  @override
  Future<UserModel> createUser({required String rawPhone, required String firstName, required String lastName}) async {
    return UserModel(uid: 'fake_user_uid', phone: rawPhone, firstName: firstName, lastName: lastName, name: '$firstName $lastName', photoUrl: '');
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  fb_auth.User? get currentUser => null;

  @override
  AuthService get authService => FakeAuthService();

  @override
  Stream<fb_auth.User?> get authStateChanges => Stream.value(null);

  @override
  Future<UserModel?> findUserByPhone(String rawPhone) async => null;

  @override
  Future<UserModel> createUser({
    required String rawPhone,
    required String firstName,
    required String lastName,
  }) async {
    return UserModel(uid: 'fake_user_uid', phone: rawPhone, firstName: firstName, lastName: lastName, name: '$firstName $lastName', photoUrl: '');
  }

  @override
  Future<void> saveLocalSession(String phone, String uid) async {}

  @override
  Future<String?> getLocalSessionPhone() async => '+919876543210';

  @override
  Future<String?> getLocalSessionUid() async => 'fake_user_uid';

  @override
  Future<void> signOut() async {}
}

void main() {
  late FakeBleService fakeBleService;
  late FakeEmergencyRepository fakeEmergencyRepo;
  late ProviderContainer container;

  setUp(() {
    fakeBleService = FakeBleService();
    fakeEmergencyRepo = FakeEmergencyRepository();
    container = ProviderContainer(
      overrides: [
        bleServiceProvider.overrideWithValue(fakeBleService),
        emergencyRepositoryProvider.overrideWithValue(fakeEmergencyRepo),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
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

    test('Hardware SOS triggering, de-duplication, and reset logic', () async {
      // 1. Initially no emergency created
      expect(fakeEmergencyRepo.createEmergencyCount, 0);

      // Connect the fake BLE device
      fakeBleService.emitConnectionState(BleConnectionState.connected);
      await Future.delayed(Duration.zero);

      // 2. Emit NORMAL packet -> no SOS triggered
      final normalPacket = SensorData(
        state: 'NORMAL',
        battery: 90,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(normalPacket);
      await Future.delayed(Duration.zero);
      expect(fakeEmergencyRepo.createEmergencyCount, 0);

      // 3. Emit EMERGENCY packet -> SOS triggered once
      final emergencyPacket = SensorData(
        state: 'EMERGENCY',
        lat: 18.520430,
        lon: 73.856743,
        gpsFresh: true,
        battery: 82,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(emergencyPacket);
      await Future.delayed(Duration.zero);

      expect(fakeEmergencyRepo.createEmergencyCount, 1);
      expect(fakeEmergencyRepo.lastTriggerType, 'hardware_sos');
      expect(fakeEmergencyRepo.lastLat, 18.520430);
      expect(fakeEmergencyRepo.lastLon, 73.856743);
      expect(container.read(mockStateProvider).mySosActive, isTrue);

      // 4. Emit another EMERGENCY packet -> createEmergency not called again (de-duplication)
      final secondEmergency = SensorData(
        state: 'EMERGENCY',
        lat: 18.520430,
        lon: 73.856743,
        gpsFresh: true,
        battery: 81,
        timestamp: DateTime.now(),
      );
      fakeBleService.emitSensorData(secondEmergency);
      await Future.delayed(Duration.zero);
      expect(fakeEmergencyRepo.createEmergencyCount, 1);

      // 5. Emit NORMAL packet -> resets trigger state
      fakeBleService.emitSensorData(normalPacket);
      await Future.delayed(Duration.zero);
      expect(fakeEmergencyRepo.createEmergencyCount, 1);

      // 6. Emit EMERGENCY packet again -> triggers second SOS
      fakeBleService.emitSensorData(emergencyPacket);
      await Future.delayed(Duration.zero);
      expect(fakeEmergencyRepo.createEmergencyCount, 2);
    });
  });
}
