import 'package:flutter_test/flutter_test.dart';
import 'package:women_safety_app/core/models/sensor_data.dart';

void main() {
  group('SensorData Parsing Tests', () {
    test('Parse Normal Packet', () {
      final json = {
        "fsr": 742,
        "accel": 1.02,
        "gyro": 23.4,
        "state": "NORMAL",
        "battery": 87
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.fsr, 742);
      expect(sensorData.accel, 1.02);
      expect(sensorData.gyro, 23.4);
      expect(sensorData.state, 'NORMAL');
      expect(sensorData.battery, 87);
      expect(sensorData.lat, isNull);
      expect(sensorData.lon, isNull);
      expect(sensorData.gpsFresh, isNull);
      expect(sensorData.timestamp, isNotNull);
    });

    test('Parse Emergency Packet', () {
      final json = {
        "state": "EMERGENCY",
        "lat": 18.520430,
        "lon": 73.856743,
        "gpsFresh": true
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.fsr, isNull);
      expect(sensorData.accel, isNull);
      expect(sensorData.gyro, isNull);
      expect(sensorData.state, 'EMERGENCY');
      expect(sensorData.battery, isNull);
      expect(sensorData.lat, 18.520430);
      expect(sensorData.lon, 73.856743);
      expect(sensorData.gpsFresh, isTrue);
      expect(sensorData.timestamp, isNotNull);
    });

    test('Parse Unknown/Invalid State Packet', () {
      final json = {
        "fsr": 123
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.state, 'UNKNOWN');
      expect(sensorData.fsr, 123);
      expect(sensorData.accel, isNull);
      expect(sensorData.timestamp, isNotNull);
    });
  });
}
