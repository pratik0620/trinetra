import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/relay_packet.dart';

class NearbyPacketReceived {
  final String endpointId;
  final RelayPacket packet;

  NearbyPacketReceived(this.endpointId, this.packet);
}

abstract class NearbyRelayService {
  Stream<NearbyPacketReceived> get packetStream;
  Stream<String> get ackStream;
  
  Future<bool> checkPermissions();
  Future<void> startDiscovery(String userName);
  Future<void> stopDiscovery();
  Future<void> startAdvertising(String userName, RelayPacket packet);
  Future<void> stopAdvertising();
  Future<void> sendAck(String endpointId, RelayPacket packet);
  Future<void> disconnectAll();
}

class NearbyRelayServiceImpl implements NearbyRelayService {
  final _packetController = StreamController<NearbyPacketReceived>.broadcast();
  final _ackController = StreamController<String>.broadcast();

  static const String serviceId = 'com.example.women_safety_app.relay';
  final Strategy strategy = Strategy.P2P_CLUSTER;

  // Track active connection endpoint IDs
  final Set<String> _connectedEndpoints = {};

  @override
  Stream<NearbyPacketReceived> get packetStream => _packetController.stream;

  @override
  Stream<String> get ackStream => _ackController.stream;

  @override
  Future<bool> checkPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ].request();

      return statuses[Permission.location]?.isGranted == true &&
          statuses[Permission.bluetoothScan]?.isGranted == true &&
          statuses[Permission.bluetoothConnect]?.isGranted == true &&
          statuses[Permission.bluetoothAdvertise]?.isGranted == true;
    }
    return true;
  }

  @override
  Future<void> startDiscovery(String userName) async {
    final hasPerms = await checkPermissions();
    if (!hasPerms) {
      debugPrint('[NEARBY_RELAY] Permissions denied for discovery');
      return;
    }

    try {
      debugPrint('[NEARBY_RELAY] Starting Nearby discovery...');
      await stopDiscovery(); // Ensure clean state before starting

      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) async {
          debugPrint('[NEARBY_RELAY] Endpoint found: $endpointId ($endpointName)');
          try {
            await Nearby().requestConnection(
              userName,
              endpointId,
              onConnectionInitiated: (id, info) async {
                debugPrint('[NEARBY_RELAY] Connection initiated with: $id');
                await _acceptConnection(id);
              },
              onConnectionResult: (id, status) {
                debugPrint('[NEARBY_RELAY] Connection result for $id: $status');
                if (status == Status.CONNECTED) {
                  _connectedEndpoints.add(id);
                } else {
                  _connectedEndpoints.remove(id);
                }
              },
              onDisconnected: (id) {
                debugPrint('[NEARBY_RELAY] Disconnected from: $id');
                _connectedEndpoints.remove(id);
              },
            );
          } catch (e) {
            debugPrint('[NEARBY_RELAY] Error requesting connection: $e');
          }
        },
        onEndpointLost: (endpointId) {
          debugPrint('[NEARBY_RELAY] Endpoint lost: $endpointId');
        },
        serviceId: serviceId,
      );
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error starting discovery: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await Nearby().stopDiscovery();
      debugPrint('[NEARBY_RELAY] Nearby discovery stopped');
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error stopping discovery: $e');
    }
  }

  @override
  Future<void> startAdvertising(String userName, RelayPacket packet) async {
    final hasPerms = await checkPermissions();
    if (!hasPerms) {
      debugPrint('[NEARBY_RELAY] Permissions denied for advertising');
      return;
    }

    try {
      debugPrint('[NEARBY_RELAY] Starting Nearby advertising...');
      await stopAdvertising(); // Ensure clean state before starting

      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (endpointId, info) async {
          debugPrint('[NEARBY_RELAY] Connection initiated (advertising): $endpointId');
          await _acceptConnection(endpointId);
          
          // Send the emergency packet immediately when connection is initiated
          final jsonString = json.encode(packet.toJson());
          debugPrint('[NEARBY_RELAY] Sending emergency packet to $endpointId: $jsonString');
          await Nearby().sendBytesPayload(
            endpointId,
            Uint8List.fromList(utf8.encode(jsonString)),
          );
        },
        onConnectionResult: (endpointId, status) {
          debugPrint('[NEARBY_RELAY] Connection result (advertising) for $endpointId: $status');
          if (status == Status.CONNECTED) {
            _connectedEndpoints.add(endpointId);
          } else {
            _connectedEndpoints.remove(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          debugPrint('[NEARBY_RELAY] Disconnected (advertising): $endpointId');
          _connectedEndpoints.remove(endpointId);
        },
        serviceId: serviceId,
      );
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error starting advertising: $e');
    }
  }

  @override
  Future<void> stopAdvertising() async {
    try {
      await Nearby().stopAdvertising();
      debugPrint('[NEARBY_RELAY] Nearby advertising stopped');
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error stopping advertising: $e');
    }
  }

  @override
  Future<void> sendAck(String endpointId, RelayPacket packet) async {
    final jsonString = json.encode(packet.toJson());
    debugPrint('[NEARBY_RELAY] Sending ACK packet to $endpointId: $jsonString');
    try {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(jsonString)),
      );
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error sending ACK: $e');
    }
  }

  @override
  Future<void> disconnectAll() async {
    for (var id in _connectedEndpoints) {
      try {
        await Nearby().disconnectFromEndpoint(id);
      } catch (_) {}
    }
    _connectedEndpoints.clear();
  }

  Future<void> _acceptConnection(String endpointId) async {
    try {
      await Nearby().acceptConnection(
        endpointId,
        onPayLoadRecieved: (id, payload) {
          if (payload.type == PayloadType.BYTES) {
            final bytes = payload.bytes;
            if (bytes != null) {
              try {
                final jsonString = utf8.decode(bytes);
                debugPrint('[NEARBY_RELAY] Received payload raw from $id: $jsonString');
                final map = json.decode(jsonString) as Map<String, dynamic>;
                
                final packet = RelayPacket.fromJson(map);
                if (packet.state == 'ACK') {
                  _ackController.add(id);
                } else {
                  _packetController.add(NearbyPacketReceived(id, packet));
                }
              } catch (e) {
                debugPrint('[NEARBY_RELAY] Error parsing payload: $e');
              }
            }
          }
        },
        onPayloadTransferUpdate: (id, update) {
          // Track progress if needed
        },
      );
    } catch (e) {
      debugPrint('[NEARBY_RELAY] Error accepting connection: $e');
    }
  }
}
