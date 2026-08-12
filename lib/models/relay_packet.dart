class RelayPacket {
  final String deviceId;
  final String state; // 'EMERGENCY', 'WARNING', 'NORMAL', 'ACK'
  final double? lat;
  final double? lon;
  final int battery;
  final int timestamp;
  final int version;

  RelayPacket({
    required this.deviceId,
    required this.state,
    this.lat,
    this.lon,
    required this.battery,
    required this.timestamp,
    this.version = 1,
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
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      battery: json['battery'] as int? ?? 100,
      timestamp: json['timestamp'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'deviceId': deviceId,
      'state': state,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      'battery': battery,
      'timestamp': timestamp,
    };
  }
}
