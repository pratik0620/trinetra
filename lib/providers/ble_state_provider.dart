import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/sensor_data.dart';
import '../core/services/ble_service.dart';
import 'app_providers.dart';
import 'mock_state_provider.dart';

class BleState {
  final BleConnectionState connectionState;
  final SensorData? sensorData;
  final DateTime? lastUpdate;
  final bool isLive;
  final int packetCount;

  const BleState({
    required this.connectionState,
    this.sensorData,
    this.lastUpdate,
    required this.isLive,
    this.packetCount = 0,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    SensorData? sensorData,
    DateTime? lastUpdate,
    bool? isLive,
    int? packetCount,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      sensorData: sensorData ?? this.sensorData,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isLive: isLive ?? this.isLive,
      packetCount: packetCount ?? this.packetCount,
    );
  }
}

final bleStateProvider = StateNotifierProvider<BleStateNotifier, BleState>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return BleStateNotifier(bleService, ref);
});

class BleStateNotifier extends StateNotifier<BleState> {
  final BleService _bleService;
  final Ref _ref;
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<BleConnectionState>? _connSub;
  Timer? _staleTimer;
  bool _isEmergencyTriggered = false;

  BleStateNotifier(this._bleService, this._ref)
      : super(BleState(
          connectionState: _bleService.currentConnectionState,
          sensorData: null,
          lastUpdate: null,
          isLive: false,
          packetCount: 0,
        )) {
    // Automatically start scanning when BleStateNotifier is created/accessed
    _bleService.startScan();

    // Listen to BLE connection changes
    _connSub = _bleService.connectionStream.listen((connState) {
      _staleTimer?.cancel();
      bool nextIsLive = state.isLive;
      if (connState != BleConnectionState.connected) {
        nextIsLive = false;
        // Reset emergency trigger flag on disconnect so we are fresh on reconnect
        _isEmergencyTriggered = false;
      }
      state = state.copyWith(
        connectionState: connState,
        isLive: nextIsLive,
      );
    });

    // Listen to BLE incoming sensor data packets
    _sensorSub = _bleService.sensorStream.listen((data) {
      _resetStaleTimer();
      state = state.copyWith(
        sensorData: data,
        lastUpdate: DateTime.now(),
        isLive: state.connectionState == BleConnectionState.connected,
        packetCount: state.packetCount + 1,
      );

      // Handle Hardware Emergency Detection
      if (data.state == 'EMERGENCY') {
        _triggerHardwareEmergency(data);
      } else {
        // If state returns to NORMAL, reset the local trigger flag
        // so a subsequent emergency can be triggered in the future.
        _isEmergencyTriggered = false;
      }
    });
  }

  Future<void> _triggerHardwareEmergency(SensorData data) async {
    if (_isEmergencyTriggered) {
      debugPrint('[RAKSHA][SOS] Hardware emergency already triggered, ignoring duplicate packet.');
      return;
    }
    _isEmergencyTriggered = true;

    debugPrint('[RAKSHA][SAFETY] Hardware emergency detected (state: EMERGENCY)');
    debugPrint('[RAKSHA][SOS] Triggering existing SOS flow');

    try {
      // 1. Fetch Auth details
      final authService = _ref.read(authServiceProvider);
      final sessionUid = await authService.getLocalSessionUid();
      final activeUid = _ref.read(activeUserUidProvider);
      final authUser = _ref.read(authRepositoryProvider).currentUser;

      final userId = activeUid ?? sessionUid ?? authUser?.uid ?? '';
      if (userId.isEmpty) {
        debugPrint('[RAKSHA][SOS] Error: Cannot trigger hardware SOS because userId is empty');
        return;
      }

      // 2. Call mock state to align local UI overlay
      _ref.read(mockStateProvider.notifier).triggerMySos();

      // 3. Call the same EmergencyRepository function
      final emergencyRepo = _ref.read(emergencyRepositoryProvider);
      final emergencyId = await emergencyRepo.createEmergency(
        userId: userId,
        deviceId: 'device_raksha_shoe_01',
        triggerType: 'hardware_sos',
        latitude: data.lat ?? 28.6139,
        longitude: data.lon ?? 77.2090,
      );

      debugPrint('====================================');
      debugPrint('[RAKSHA][SOS] Hardware Emergency Created Successfully');
      debugPrint('userId = $userId');
      debugPrint('emergencyId = $emergencyId');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('[RAKSHA][SOS] Error creating hardware emergency in Firestore: $e');
    }
  }

  void _resetStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(isLive: false);
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _connSub?.cancel();
    _staleTimer?.cancel();
    super.dispose();
  }
}
