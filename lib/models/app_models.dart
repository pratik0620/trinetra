enum SafetyStatusEnum {
  safe,
  warning,
  emergency,
}

enum GuardianEmergencyStage {
  none,
  incomingNotification,
  activeSOS,
  responding,
  resolved,
}

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String avatarUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarUrl,
  });
}

class ShoeStatusModel {
  final bool isConnected;
  final int batteryPercent;
  final bool isBleConnected;
  final bool isGpsAvailable;
  final bool is4gConnected;
  final String lastSyncedText;

  const ShoeStatusModel({
    required this.isConnected,
    required this.batteryPercent,
    required this.isBleConnected,
    required this.isGpsAvailable,
    required this.is4gConnected,
    required this.lastSyncedText,
  });

  ShoeStatusModel copyWith({
    bool? isConnected,
    int? batteryPercent,
    bool? isBleConnected,
    bool? isGpsAvailable,
    bool? is4gConnected,
    String? lastSyncedText,
  }) {
    return ShoeStatusModel(
      isConnected: isConnected ?? this.isConnected,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isBleConnected: isBleConnected ?? this.isBleConnected,
      isGpsAvailable: isGpsAvailable ?? this.isGpsAvailable,
      is4gConnected: is4gConnected ?? this.is4gConnected,
      lastSyncedText: lastSyncedText ?? this.lastSyncedText,
    );
  }
}

class NetworkContact {
  final String id;
  final String name;
  final String relationship;
  final bool isSafe;
  final String avatarUrl;
  final bool isProtectedByMe;
  final bool isProtectingMe;
  final bool sosActive;

  const NetworkContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.isSafe,
    required this.avatarUrl,
    required this.isProtectedByMe,
    required this.isProtectingMe,
    this.sosActive = false,
  });
}

class HistoryEventModel {
  final String id;
  final String title;
  final String subtitle;
  final String timestamp;
  final String badgeText;
  final EventType type;

  const HistoryEventModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.badgeText,
    required this.type,
  });
}

enum EventType {
  normal,
  warning,
  critical,
  resolved,
}

class GuardianEmergencySession {
  final String victimName;
  final String triggerType;
  final int secondsAgo;
  final double distanceKm;
  final String locationText;
  final String responderName;
  final String durationText;

  const GuardianEmergencySession({
    required this.victimName,
    required this.triggerType,
    required this.secondsAgo,
    required this.distanceKm,
    required this.locationText,
    required this.responderName,
    required this.durationText,
  });
}
