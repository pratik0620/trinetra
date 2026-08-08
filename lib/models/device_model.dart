import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String deviceId;
  final String ownerId;
  final String name;
  final int battery;
  final String bleStatus;
  final String gpsStatus;
  final String cellularStatus;
  final DateTime? lastSeen;
  final String firmwareVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeviceModel({
    required this.deviceId,
    required this.ownerId,
    required this.name,
    required this.battery,
    required this.bleStatus,
    required this.gpsStatus,
    required this.cellularStatus,
    this.lastSeen,
    required this.firmwareVersion,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DeviceModel(
      deviceId: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? 'RAKSHA Shoe',
      battery: data['battery'] ?? 84,
      bleStatus: data['bleStatus'] ?? 'connected',
      gpsStatus: data['gpsStatus'] ?? 'available',
      cellularStatus: data['cellularStatus'] ?? 'connected',
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      firmwareVersion: data['firmwareVersion'] ?? 'v2.1.0',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'ownerId': ownerId,
      'name': name,
      'battery': battery,
      'bleStatus': bleStatus,
      'gpsStatus': gpsStatus,
      'cellularStatus': cellularStatus,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : FieldValue.serverTimestamp(),
      'firmwareVersion': firmwareVersion,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
