import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyModel {
  final String id;
  final String userId;
  final String deviceId;
  final String triggerType; // 'manual_sos', 'stomp', 'fall'
  final String status; // 'verifying', 'active', 'responding', 'resolved', 'cancelled'
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? respondingGuardianId;

  const EmergencyModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.triggerType,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.respondingGuardianId,
  });

  factory EmergencyModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EmergencyModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      deviceId: data['deviceId'] ?? '',
      triggerType: data['triggerType'] ?? 'manual_sos',
      status: data['status'] ?? 'active',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 28.6139,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 77.2090,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 5.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      respondingGuardianId: data['respondingGuardianId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'triggerType': triggerType,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'respondingGuardianId': respondingGuardianId,
    };
  }
}
