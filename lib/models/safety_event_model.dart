import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyEventFirestoreModel {
  final String id;
  final String userId;
  final String type;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? emergencyId;

  const SafetyEventFirestoreModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.emergencyId,
  });

  factory SafetyEventFirestoreModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SafetyEventFirestoreModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'normal',
      status: data['status'] ?? 'Safe',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 28.6139,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 77.2090,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emergencyId: data['emergencyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'emergencyId': emergencyId,
    };
  }
}
