import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/sensor_data.dart';
import '../core/services/ble_service.dart';
import 'app_providers.dart';

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
  return BleStateNotifier(bleService);
});

class BleStateNotifier extends StateNotifier<BleState> {
  final BleService _bleService;
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<BleConnectionState>? _connSub;
  Timer? _staleTimer;

  BleStateNotifier(this._bleService)
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
    });
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
