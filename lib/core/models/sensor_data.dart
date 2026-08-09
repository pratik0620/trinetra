class SensorData {
  final int? fsr;
  final double? accel;
  final double? gyro;
  final String state;
  final double? lat;
  final double? lon;
  final int? battery;
  final bool? gpsFresh;
  final DateTime timestamp;

  SensorData({
    this.fsr,
    this.accel,
    this.gyro,
    required this.state,
    this.lat,
    this.lon,
    this.battery,
    this.gpsFresh,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      fsr: json['fsr'] as int?,
      accel: (json['accel'] as num?)?.toDouble(),
      gyro: (json['gyro'] as num?)?.toDouble(),
      state: json['state'] as String? ?? 'UNKNOWN',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      battery: json['battery'] as int?,
      gpsFresh: json['gpsFresh'] as bool?,
      timestamp: DateTime.now(),
    );
  }
}
