import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/relay_service.dart';
import '../models/relay_packet.dart';
import '../core/services/ble_service.dart';
import '../core/models/sensor_data.dart';
import 'ble_state_provider.dart';
import 'app_providers.dart';

class RelayStateModel {
  final RelayState relayState;
  final List<RelayPacket> receivedPackets;
  final bool isScanning;
  final bool isAdvertising;
  final bool isAcknowledged;
  final bool isRelayedSuccessfully;

  const RelayStateModel({
    required this.relayState,
    required this.receivedPackets,
    this.isScanning = false,
    this.isAdvertising = false,
    this.isAcknowledged = false,
    this.isRelayedSuccessfully = false,
  });

  RelayStateModel copyWith({
    RelayState? relayState,
    List<RelayPacket>? receivedPackets,
    bool? isScanning,
    bool? isAdvertising,
    bool? isAcknowledged,
    bool? isRelayedSuccessfully,
  }) {
    return RelayStateModel(
      relayState: relayState ?? this.relayState,
      receivedPackets: receivedPackets ?? this.receivedPackets,
      isScanning: isScanning ?? this.isScanning,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      isRelayedSuccessfully: isRelayedSuccessfully ?? this.isRelayedSuccessfully,
    );
  }
}

final relayServiceProvider = Provider<RelayService>((ref) {
  final service = RelayServiceImpl();
  ref.onDispose(() {
    service.stopAdvertising();
    service.stopScanning();
  });
  return service;
});

final relayStateProvider = StateNotifierProvider<RelayNotifier, RelayStateModel>((ref) {
  final relayService = ref.watch(relayServiceProvider);
  return RelayNotifier(relayService, ref);
});

class RelayNotifier extends StateNotifier<RelayStateModel> {
  final RelayService _relayService;
  final Ref _ref;
  
  StreamSubscription<RelayPacket>? _packetSubscription;
  StreamSubscription<RelayState>? _stateSubscription;
  Timer? _ackCheckTimer;
  bool _isDisposed = false;

  RelayNotifier(this._relayService, this._ref)
      : super(const RelayStateModel(
          relayState: RelayState.idle,
          receivedPackets: [],
        )) {
    
    // 1. Listen to service's internal state
    _stateSubscription = _relayService.stateStream.listen((stateVal) {
      if (_isDisposed) return;
      state = state.copyWith(relayState: stateVal);
    });

    // 2. Listen to service's scanned packets
    _packetSubscription = _relayService.packetStream.listen((packet) {
      _handleIncomingPacket(packet);
    });

    // 3. Listen to BLE state provider changes to trigger/stop advertising and scanning
    _ref.listen<BleState>(bleStateProvider, (previous, next) {
      if (_isDisposed) return;
      
      final isConnected = next.connectionState == BleConnectionState.connected;
      final wasConnected = previous?.connectionState == BleConnectionState.connected;
      
      // Update scanning based on connection state (Adaptive Scanning)
      if (isConnected && !wasConnected) {
        _stopScanning();
      } else if (!isConnected && wasConnected) {
        _startScanning();
      }

      // Handle EMERGENCY state changes
      final isEmergency = next.sensorData?.state == 'EMERGENCY';
      final wasEmergency = previous?.sensorData?.state == 'EMERGENCY';
      
      if (isEmergency && !wasEmergency) {
        _startAdvertising(next.sensorData);
      } else if (!isEmergency && wasEmergency) {
        _stopAdvertising();
      }
    });

    // 4. Initial scan/advertise check on startup
    final initialBleState = _ref.read(bleStateProvider);
    final initialConnected = initialBleState.connectionState == BleConnectionState.connected;
    final initialEmergency = initialBleState.sensorData?.state == 'EMERGENCY';

    if (initialEmergency) {
      _startAdvertising(initialBleState.sensorData);
    } else if (!initialConnected) {
      _startScanning();
    }
  }

  Future<void> _startScanning() async {
    if (state.isAdvertising) return;
    state = state.copyWith(isScanning: true);
    await _relayService.startScanning();
  }

  Future<void> _stopScanning() async {
    state = state.copyWith(isScanning: false);
    await _relayService.stopScanning();
  }

  void _startAdvertising(SensorData? sensorData) {
    if (state.isAcknowledged) return;
    _ackCheckTimer?.cancel();
    
    final deviceId = 'RK1'; // Compact ID for hackathon demo to fit in BLE Adv
    final battery = sensorData?.battery ?? 100;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final packet = RelayPacket(
      deviceId: deviceId,
      state: 'EMERGENCY',
      battery: battery,
      timestamp: timestamp,
    );

    _advertiseAndScanAckLoop(packet);
  }

  void _advertiseAndScanAckLoop(RelayPacket packet) async {
    if (_isDisposed || state.isAcknowledged) {
      await _relayService.stopAdvertising();
      await _relayService.stopScanning();
      return;
    }

    // Toggle: Stop scanning and start advertising the emergency packet
    state = state.copyWith(isAdvertising: true, isScanning: false);
    await _relayService.stopScanning();
    await _relayService.startAdvertising(packet);

    // Advertise for 8 seconds
    _ackCheckTimer = Timer(const Duration(seconds: 8), () async {
      if (_isDisposed || state.isAcknowledged) return;

      await _relayService.stopAdvertising();
      
      // Scan for ACK for 2 seconds
      state = state.copyWith(isScanning: true);
      await _relayService.startScanning();

      _ackCheckTimer = Timer(const Duration(seconds: 2), () {
        if (_isDisposed) return;
        
        // If we still haven't received ACK, repeat the loop
        if (!state.isAcknowledged && state.isAdvertising) {
          _advertiseAndScanAckLoop(packet);
        }
      });
    });
  }

  Future<void> _stopAdvertising() async {
    _ackCheckTimer?.cancel();
    _ackCheckTimer = null;
    state = state.copyWith(isAdvertising: false);
    await _relayService.stopAdvertising();
    
    final isConnected = _ref.read(bleStateProvider).connectionState == BleConnectionState.connected;
    if (!isConnected) {
      _startScanning();
    } else {
      _stopScanning();
    }
  }

  void _handleIncomingPacket(RelayPacket packet) {
    if (packet.state == 'ACK') {
      if (packet.deviceId == 'RK1') {
        debugPrint('[RELAY] Phone A received ACK for emergency!');
        state = state.copyWith(isAcknowledged: true);
        _stopAdvertising();
      }
    } else if (packet.state == 'EMERGENCY') {
      debugPrint('[RELAY] Phone B received emergency packet from ${packet.deviceId}');
      _handleReceivedEmergency(packet);
    }
  }

  Future<void> _handleReceivedEmergency(RelayPacket packet) async {
    if (_isDisposed) return;
    
    // Add to list of received packets
    state = state.copyWith(
      receivedPackets: [...state.receivedPackets, packet],
    );

    // Forward to Firebase
    try {
      final authUser = _ref.read(authRepositoryProvider).currentUser;
      final currentUserId = authUser?.uid ?? 'unknown_relay_phone';
      
      final db = FirebaseFirestore.instance;

      // Acquire Phone B's location for approximate relay coordinates
      double lat = 0.0;
      double lon = 0.0;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (e) {
        debugPrint('[RELAY] Location acquisition failed, using defaults: $e');
        lat = 28.6139; // Fallback lat
        lon = 77.2090; // Fallback lon
      }

      // Write the emergency document
      final docRef = db.collection('emergencies').doc();
      final emergencyData = {
        'id': docRef.id,
        'userId': packet.deviceId, // Victim ID from packet ("RK1")
        'deviceId': 'device_raksha_shoe_01',
        'triggerType': 'hardware_sos',
        'status': 'active',
        'latitude': lat,
        'longitude': lon,
        'accuracy': 5.0,
        'isFallback': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'relay': true,
        'relayDeviceId': currentUserId,
        'relayTimestamp': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(emergencyData);
      debugPrint('[RELAY] Relayed emergency document created: ${docRef.id}');

      // Write safety event document
      final eventRef = db.collection('safety_events').doc();
      final eventData = {
        'id': eventRef.id,
        'userId': packet.deviceId,
        'type': 'sos_triggered',
        'status': 'Critical',
        'latitude': lat,
        'longitude': lon,
        'timestamp': FieldValue.serverTimestamp(),
        'emergencyId': docRef.id,
      };
      
      await eventRef.set(eventData);
      debugPrint('[RELAY] Relayed safety event document created: ${eventRef.id}');
      
      // Update state to show relayed successfully
      state = state.copyWith(isRelayedSuccessfully: true);
      
      // Now, start advertising the ACK beacon for 5 seconds to notify Phone A
      await _relayService.stopScanning();
      
      final ackPacket = RelayPacket(
        deviceId: packet.deviceId, // 'RK1'
        state: 'ACK',
        battery: 100,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      await _relayService.startAdvertising(ackPacket);
      
      Timer(const Duration(seconds: 5), () async {
        if (_isDisposed) return;
        await _relayService.stopAdvertising();
        state = state.copyWith(isRelayedSuccessfully: false);
        _startScanning();
      });
      
    } catch (e) {
      debugPrint('[RELAY] Error forwarding relayed emergency: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ackCheckTimer?.cancel();
    _packetSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
