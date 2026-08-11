import 'emergency_model.dart';

class OfflineEmergencyModel {
  final String emergencyId;
  final String userId;
  final String userName;
  final String? phoneNumber;
  final String triggerType; // 'manual_sos', 'stomp', 'fall', 'sms'
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final String status; // 'active', 'responding', 'resolved'
  final String source; // 'fcm', 'sms', 'manual', 'shoe'
  final bool isOfflineData;
  final String? respondingGuardianId;

  const OfflineEmergencyModel({
    required this.emergencyId,
    required this.userId,
    required this.userName,
    this.phoneNumber,
    required this.triggerType,
    this.latitude,
    this.longitude,
    required this.timestamp,
    required this.status,
    required this.source,
    this.isOfflineData = false,
    this.respondingGuardianId,
  });

  factory OfflineEmergencyModel.fromEmergencyModel(
    EmergencyModel model, {
    String? userName,
    String? phoneNumber,
  }) {
    return OfflineEmergencyModel(
      emergencyId: model.id,
      userId: model.userId,
      userName: userName ?? 'RAKSHA Contact',
      phoneNumber: phoneNumber,
      triggerType: model.triggerType,
      latitude: model.latitude == 0.0 ? null : model.latitude,
      longitude: model.longitude == 0.0 ? null : model.longitude,
      timestamp: model.createdAt ?? DateTime.now(),
      status: _normalizeStatus(model.status),
      source: model.triggerType == 'manual_sos' ? 'manual' : 'shoe',
      isOfflineData: false,
      respondingGuardianId: model.respondingGuardianId,
    );
  }

  factory OfflineEmergencyModel.fromFcmPayload(Map<String, dynamic> data) {
    final lat = double.tryParse(data['latitude']?.toString() ?? '');
    final lng = double.tryParse(data['longitude']?.toString() ?? '');
    final rawTime = data['timestamp']?.toString();
    final parsedTime = rawTime != null ? DateTime.tryParse(rawTime) : null;

    return OfflineEmergencyModel(
      emergencyId: data['emergencyId']?.toString() ?? 'emergency_fcm_${DateTime.now().millisecondsSinceEpoch}',
      userId: data['userId']?.toString() ?? data['triggeredByUserId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? data['victimName']?.toString() ?? 'RAKSHA Contact',
      phoneNumber: data['phoneNumber']?.toString() ?? data['phone']?.toString(),
      triggerType: data['triggerType']?.toString() ?? 'manual_sos',
      latitude: (lat != null && lat != 0.0) ? lat : null,
      longitude: (lng != null && lng != 0.0) ? lng : null,
      timestamp: parsedTime ?? DateTime.now(),
      status: _normalizeStatus(data['status']?.toString()),
      source: 'fcm',
      isOfflineData: true,
      respondingGuardianId: data['respondingGuardianId']?.toString(),
    );
  }

  factory OfflineEmergencyModel.fromSms(Map<String, dynamic> smsMap) {
    final lat = double.tryParse(smsMap['latitude']?.toString() ?? '');
    final lng = double.tryParse(smsMap['longitude']?.toString() ?? '');

    return OfflineEmergencyModel(
      emergencyId: smsMap['emergencyId']?.toString() ?? 'sms_${DateTime.now().millisecondsSinceEpoch}',
      userId: smsMap['senderId']?.toString() ?? '',
      userName: smsMap['senderName']?.toString() ?? smsMap['senderPhone']?.toString() ?? 'SMS Emergency Contact',
      phoneNumber: smsMap['senderPhone']?.toString(),
      triggerType: smsMap['triggerType']?.toString() ?? 'sms',
      latitude: (lat != null && lat != 0.0) ? lat : null,
      longitude: (lng != null && lng != 0.0) ? lng : null,
      timestamp: DateTime.now(),
      status: _normalizeStatus(smsMap['status']?.toString()),
      source: 'sms',
      isOfflineData: true,
    );
  }

  static String _normalizeStatus(String? rawStatus) {
    final s = (rawStatus ?? 'active').toLowerCase().trim();
    if (s == 'responding' || s == 'acknowledged') {
      return 'responding';
    } else if (s == 'resolved' || s == 'cancelled') {
      return 'resolved';
    }
    return 'active';
  }

  OfflineEmergencyModel copyWith({
    String? emergencyId,
    String? userId,
    String? userName,
    String? phoneNumber,
    String? triggerType,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? status,
    String? source,
    bool? isOfflineData,
    String? respondingGuardianId,
  }) {
    return OfflineEmergencyModel(
      emergencyId: emergencyId ?? this.emergencyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      triggerType: triggerType ?? this.triggerType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      source: source ?? this.source,
      isOfflineData: isOfflineData ?? this.isOfflineData,
      respondingGuardianId: respondingGuardianId ?? this.respondingGuardianId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emergencyId': emergencyId,
      'userId': userId,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'triggerType': triggerType,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'source': source,
      'isOfflineData': isOfflineData,
      'respondingGuardianId': respondingGuardianId,
    };
  }
}
