import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyLocationModel {
  final String userId;
  final String name;
  final String role; // 'victim' or 'guardian'
  final double latitude;
  final double longitude;
  final bool isFallback;
  final DateTime updatedAt;

  const EmergencyLocationModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.latitude,
    required this.longitude,
    this.isFallback = false,
    required this.updatedAt,
  });

  factory EmergencyLocationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawTimestamp = data['updatedAt'];
    DateTime parsedTime = DateTime.now();

    if (rawTimestamp is Timestamp) {
      parsedTime = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTime = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    return EmergencyLocationModel(
      userId: data['userId']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? (data['role'] == 'victim' ? 'Victim' : 'Guardian'),
      role: (data['role']?.toString() ?? 'guardian').toLowerCase(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      isFallback: data['isFallback'] == true || data['isFallback']?.toString() == 'true',
      updatedAt: parsedTime,
    );
  }

  factory EmergencyLocationModel.fromMap(Map<String, dynamic> data) {
    final rawTime = data['updatedAt'];
    DateTime parsed = DateTime.now();
    if (rawTime is String) {
      parsed = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is DateTime) {
      parsed = rawTime;
    }

    return EmergencyLocationModel(
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? 'User',
      role: (data['role']?.toString() ?? 'guardian').toLowerCase(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      isFallback: data['isFallback'] == true || data['isFallback']?.toString() == 'true',
      updatedAt: parsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'isFallback': isFallback,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isVictim => role == 'victim';
  bool get isGuardian => role == 'guardian';
  bool get isStale => DateTime.now().difference(updatedAt).inSeconds > 30;

  int get secondsAgo => DateTime.now().difference(updatedAt).inSeconds;
}
