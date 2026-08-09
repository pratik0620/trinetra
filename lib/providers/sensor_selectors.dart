import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/sensor_data.dart';
import '../core/services/ble_service.dart';
import '../models/app_models.dart';
import 'ble_state_provider.dart';
import 'mock_state_provider.dart';

SafetyStatusEnum mapSensorStateToSafetyStatus(String? sensorState) {
  if (sensorState == 'EMERGENCY') {
    return SafetyStatusEnum.emergency;
  } else if (sensorState == 'STOMP_PENDING') {
    return SafetyStatusEnum.warning;
  }
  return SafetyStatusEnum.safe;
}

ShoeStatusModel mapSensorToShoeStatus(
  SensorData? data,
  BleConnectionState connectionState,
  String lastSyncedText,
) {
  final isConnected = connectionState == BleConnectionState.connected;
  return ShoeStatusModel(
    isConnected: isConnected,
    batteryPercent: data?.battery ?? 0,
    isBleConnected: isConnected,
    isGpsAvailable: data?.gpsFresh ?? false,
    is4gConnected: isConnected,
    lastSyncedText: lastSyncedText,
  );
}

final effectiveSensorProvider = Provider<SensorData?>((ref) {
  final bleState = ref.watch(bleStateProvider);
  if (bleState.isLive) {
    return bleState.sensorData;
  } else {
    final mockState = ref.watch(mockStateProvider);
    final shoe = mockState.shoeStatus;
    return SensorData(
      state: mockState.safetyStatus == SafetyStatusEnum.emergency ? 'EMERGENCY' : 'NORMAL',
      battery: shoe.batteryPercent,
      gpsFresh: shoe.isGpsAvailable,
      timestamp: DateTime.now(),
    );
  }
});

final effectiveSafetyStatusProvider = Provider<SafetyStatusEnum>((ref) {
  final bleState = ref.watch(bleStateProvider);
  if (bleState.isLive) {
    return mapSensorStateToSafetyStatus(bleState.sensorData?.state);
  } else {
    return ref.watch(mockStateProvider).safetyStatus;
  }
});

final tickerProvider = StreamProvider.family<int, int>((ref, seconds) {
  return Stream.periodic(Duration(seconds: seconds), (x) => x);
});

final lastUpdateDisplayProvider = Provider<String>((ref) {
  final lastUpdate = ref.watch(bleStateProvider.select((s) => s.lastUpdate));
  if (lastUpdate == null) {
    return 'Never';
  }

  // Ticks every second to update display dynamically
  ref.watch(tickerProvider(1));

  final difference = DateTime.now().difference(lastUpdate);
  final seconds = difference.inSeconds;

  if (seconds < 2) {
    return 'Just now';
  } else if (seconds < 60) {
    return '$seconds sec ago';
  } else {
    final minutes = difference.inMinutes;
    return '$minutes min ago';
  }
});

final effectiveShoeStatusProvider = Provider<ShoeStatusModel>((ref) {
  final bleState = ref.watch(bleStateProvider);
  if (bleState.isLive) {
    final lastSyncedText = ref.watch(lastUpdateDisplayProvider);
    return mapSensorToShoeStatus(
      bleState.sensorData,
      bleState.connectionState,
      lastSyncedText,
    );
  } else {
    return ref.watch(mockStateProvider).shoeStatus;
  }
});
