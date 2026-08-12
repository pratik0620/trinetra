import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/nearby_relay_service.dart';
import '../models/relay_packet.dart';
import 'ble_state_provider.dart';
import 'app_providers.dart';
import '../models/emergency_model.dart';
import '../models/offline_emergency_model.dart';
import 'mock_state_provider.dart';
import '../models/app_models.dart';

enum RelayState {
  idle,
  advertising,
  receiving,
  relayed,
  acknowledged
}

class NearbyRelayState {
  final RelayState relayState;
  final String? error;
  final String? activeEmergencyId;
  final bool isAdvertising;
  final bool isScanning;

  NearbyRelayState({
    required this.relayState,
    this.error,
    this.activeEmergencyId,
    required this.isAdvertising,
    required this.isScanning,
  });

  NearbyRelayState copyWith({
    RelayState? relayState,
    String? error,
    String? activeEmergencyId,
    bool? isAdvertising,
    bool? isScanning,
  }) {
    return NearbyRelayState(
      relayState: relayState ?? this.relayState,
      error: error ?? this.error,
      activeEmergencyId: activeEmergencyId ?? this.activeEmergencyId,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

final nearbyRelayServiceProvider = Provider<NearbyRelayService>((ref) {
  return NearbyRelayServiceImpl();
});

final nearbyRelayStateProvider = StateNotifierProvider<NearbyRelayNotifier, NearbyRelayState>((ref) {
  final service = ref.watch(nearbyRelayServiceProvider);
  return NearbyRelayNotifier(service, ref);
});

class NearbyRelayNotifier extends StateNotifier<NearbyRelayState> {
  final NearbyRelayService _nearbyService;
  final Ref _ref;
  
  StreamSubscription<NearbyPacketReceived>? _packetSub;
  StreamSubscription<String>? _ackSub;
  
  Timer? _ackTimeoutTimer;
  Timer? _retryTimer;
  
  final Set<String> _processedPackets = {};

  NearbyRelayNotifier(this._nearbyService, this._ref)
      : super(NearbyRelayState(
          relayState: RelayState.idle,
          isAdvertising: false,
          isScanning: false,
        )) {
    
    _packetSub = _nearbyService.packetStream.listen(_handleIncomingPacket);
    _ackSub = _nearbyService.ackStream.listen(_handleIncomingAck);

    _ref.listen<BleState>(bleStateProvider, (previous, next) {
      final isEmergency = next.sensorData?.state == 'EMERGENCY';
      final wasEmergency = previous?.sensorData?.state == 'EMERGENCY';
      
      if (isEmergency && !wasEmergency) {
        final data = next.sensorData!;
        final packet = RelayPacket(
          deviceId: 'RK1',
          state: 'EMERGENCY',
          lat: data.lat ?? 12.9716,
          lon: data.lon ?? 77.5946,
          battery: data.battery ?? 100,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        _startAdvertising(packet);
      } else if (!isEmergency && wasEmergency) {
        final mockState = _ref.read(mockStateProvider);
        final mockEmergency = mockState.safetyStatus == SafetyStatusEnum.emergency || mockState.mySosActive;
        if (!mockEmergency) {
          _stopAdvertising();
        }
      }
    });

    _ref.listen<RAKSHAAppState>(mockStateProvider, (previous, next) {
      final isEmergency = next.safetyStatus == SafetyStatusEnum.emergency || next.mySosActive;
      final wasEmergency = previous?.safetyStatus == SafetyStatusEnum.emergency || previous?.mySosActive == true;

      if (isEmergency && !wasEmergency) {
        final packet = RelayPacket(
          deviceId: 'RK1',
          state: 'EMERGENCY',
          lat: 12.9716,
          lon: 77.5946,
          battery: 100,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        _startAdvertising(packet);
      } else if (!isEmergency && wasEmergency) {
        final bleState = _ref.read(bleStateProvider);
        final bleEmergency = bleState.sensorData?.state == 'EMERGENCY';
        if (!bleEmergency) {
          _stopAdvertising();
        }
      }
    });

    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    state = state.copyWith(isScanning: true, relayState: RelayState.idle);
    final userName = 'User_${DateTime.now().millisecondsSinceEpoch}';
    await _nearbyService.startDiscovery(userName);
  }

  void _startAdvertising(RelayPacket packet) async {
    _stopAdvertisingTimers();
    
    final userName = 'Victim_${packet.deviceId}';
    await _nearbyService.startAdvertising(userName, packet);
    state = state.copyWith(
      relayState: RelayState.advertising,
      isAdvertising: true,
    );
    
    _ackTimeoutTimer = Timer(const Duration(seconds: 20), () async {
      debugPrint('[NEARBY_RELAY] 20 seconds passed without ACK.');
      if (state.relayState == RelayState.advertising) {
        _ackTimeoutTimer = Timer(const Duration(seconds: 10), () async {
          debugPrint('[NEARBY_RELAY] 30 seconds passed total without ACK. Stopping advertising.');
          await _stopAdvertising();
          
          _retryTimer = Timer(const Duration(seconds: 10), () {
            final currentBleState = _ref.read(bleStateProvider);
            if (currentBleState.sensorData?.state == 'EMERGENCY') {
              debugPrint('[NEARBY_RELAY] Retrying emergency advertising...');
              _startAdvertising(packet);
            }
          });
        });
      }
    });
  }

  void _stopAdvertisingTimers() {
    _ackTimeoutTimer?.cancel();
    _ackTimeoutTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> _stopAdvertising() async {
    _stopAdvertisingTimers();
    await _nearbyService.stopAdvertising();
    await _nearbyService.disconnectAll();
    state = state.copyWith(
      relayState: RelayState.idle,
      isAdvertising: false,
    );
  }

  void _handleIncomingAck(String endpointId) {
    debugPrint('[NEARBY_RELAY] Received ACK from $endpointId');
    _stopAdvertisingTimers();
    _nearbyService.stopAdvertising();
    _nearbyService.disconnectAll();
    
    state = state.copyWith(
      relayState: RelayState.acknowledged,
      isAdvertising: false,
    );
  }

  void _handleIncomingPacket(NearbyPacketReceived received) async {
    final packet = received.packet;
    final endpointId = received.endpointId;
    
    if (packet.state == 'ACK') {
      return;
    }
    
    final key = '${packet.deviceId}_${packet.timestamp}';
    if (_processedPackets.contains(key)) {
      debugPrint('[NEARBY_RELAY] Duplicate packet ignored: $key');
      return;
    }
    _processedPackets.add(key);

    debugPrint('[NEARBY_RELAY] Processed new emergency packet: $key');
    state = state.copyWith(relayState: RelayState.receiving);
    
    try {
      final notifService = _ref.read(notificationServiceProvider);
      notifService.showNotification(
        title: '🚨 NEARBY EMERGENCY DETECTED',
        body: 'Device ${packet.deviceId} is in EMERGENCY! Forwarding coordinates...',
        payload: packet.deviceId,
      );
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error triggering local notification: $e');
    }

    String relayerUid = 'unknown_relayer';
    try {
      final authService = _ref.read(authServiceProvider);
      final sessionUid = await authService.getLocalSessionUid();
      final activeUid = _ref.read(activeUserUidProvider);
      final authUser = _ref.read(authRepositoryProvider).currentUser;
      relayerUid = activeUid ?? sessionUid ?? authUser?.uid ?? 'unknown_relayer';
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error fetching relayer UID: $e');
    }

    final docId = FirebaseFirestore.instance.collection('emergencies').doc().id;
    final emergency = EmergencyModel(
      id: docId,
      userId: packet.deviceId,
      deviceId: packet.deviceId,
      triggerType: 'relay_sos',
      status: 'active',
      latitude: packet.lat ?? 12.9716,
      longitude: packet.lon ?? 77.5946,
      accuracy: 0.0,
      isFallback: true,
      createdAt: DateTime.now(),
    );

    final map = emergency.toMap();
    map['relay'] = true;
    map['relayDeviceId'] = relayerUid;
    map['relayTimestamp'] = Timestamp.fromMillisecondsSinceEpoch(packet.timestamp * 1000);
    map['relayMethod'] = 'nearby_connections';

    try {
      await FirebaseFirestore.instance.collection('emergencies').doc(docId).set(map);
      debugPrint('[NEARBY_RELAY] Emergency packet successfully synced to Firestore.');
      state = state.copyWith(relayState: RelayState.relayed);
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error syncing packet to Firestore (might be offline): $e');
      try {
        final repo = _ref.read(emergencyRepositoryProvider);
        final offlineModel = OfflineEmergencyModel(
          emergencyId: docId,
          userId: packet.deviceId,
          userName: 'Relayed Contact',
          triggerType: 'relay_sos',
          latitude: packet.lat ?? 12.9716,
          longitude: packet.lon ?? 77.5946,
          isFallback: true,
          timestamp: DateTime.fromMillisecondsSinceEpoch(packet.timestamp * 1000),
          status: 'active',
          source: 'fcm',
        );
        repo.registerOfflineEmergency(offlineModel);
      } catch (ex) {
        debugPrint('[NEARBY_RELAY] Failed registering offline fallback: $ex');
      }
    }

    final ackPacket = RelayPacket(
      deviceId: 'ACK',
      state: 'ACK',
      battery: 100,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
    await _nearbyService.sendAck(endpointId, ackPacket);
  }

  @override
  void dispose() {
    _packetSub?.cancel();
    _ackSub?.cancel();
    _stopAdvertisingTimers();
    super.dispose();
  }
}
