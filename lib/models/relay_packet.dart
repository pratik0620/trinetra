class RelayPacket {
  final String deviceId;
  final String state; // 'EMERGENCY', 'WARNING', 'NORMAL', 'ACK'
  final int battery;
  final int timestamp;

  RelayPacket({
    required this.deviceId,
    required this.state,
    required this.battery,
    required this.timestamp,
  });

  /// Serializes the packet into a compact CSV string for BLE transmission
  String toCsv() {
    final stateCode = state == 'EMERGENCY'
        ? 'E'
        : (state == 'ACK'
            ? 'A'
            : (state == 'WARNING' || state == 'STOMP_PENDING' ? 'F' : 'N'));
    return '$deviceId,$stateCode,$battery,$timestamp';
  }

  /// Parses the packet from a compact CSV string received over BLE
  factory RelayPacket.fromCsv(String csv) {
    final parts = csv.split(',');
    if (parts.length < 4) {
      throw const FormatException('Invalid CSV packet format');
    }
    
    final deviceId = parts[0].trim();
    final stateCode = parts[1].trim().toUpperCase();
    
    String state;
    if (stateCode == 'E') {
      state = 'EMERGENCY';
    } else if (stateCode == 'A') {
      state = 'ACK';
    } else if (stateCode == 'F') {
      state = 'WARNING';
    } else {
      state = 'NORMAL';
    }
    
    final battery = int.tryParse(parts[2].trim()) ?? 100;
    final timestamp = int.tryParse(parts[3].trim()) ?? 0;
    
    return RelayPacket(
      deviceId: deviceId,
      state: state,
      battery: battery,
      timestamp: timestamp,
    );
  }

  factory RelayPacket.fromJson(Map<String, dynamic> json) {
    return RelayPacket(
      deviceId: json['deviceId'] as String? ?? '',
      state: json['state'] as String? ?? 'UNKNOWN',
      battery: json['battery'] as int? ?? 100,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'state': state,
      'battery': battery,
      'timestamp': timestamp,
    };
  }
}
