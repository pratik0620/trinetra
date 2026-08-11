import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/emergency_repository.dart';

class LiveLocationService {
  final EmergencyRepository _emergencyRepository;
  Timer? _timer;
  String? _activeEmergencyId;

  LiveLocationService({EmergencyRepository? emergencyRepository})
      : _emergencyRepository = emergencyRepository ?? EmergencyRepository();

  /// Starts publishing live GPS updates every ~5 seconds to Firestore subcollection:
  /// emergencies/{emergencyId}/locations/{userId}
  Future<void> startTracking({
    required String emergencyId,
    required String userId,
    required String name,
    required String role, // 'victim' or 'guardian'
  }) async {
    if (emergencyId.isEmpty || userId.isEmpty) return;

    // Stop any existing tracking loop first
    stopTracking();
    _activeEmergencyId = emergencyId;

    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      debugPrint('LiveLocationService note: Location permission denied');
      return;
    }

    // Publish initial location immediately
    await _publishCurrentPosition(emergencyId, userId, name, role);

    // Periodically publish location every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_activeEmergencyId != emergencyId) {
        stopTracking();
        return;
      }
      await _publishCurrentPosition(emergencyId, userId, name, role);
    });

    debugPrint('LiveLocationService: Started $role tracking for $name in emergency $emergencyId');
  }

  Future<void> _publishCurrentPosition(
    String emergencyId,
    String userId,
    String name,
    String role,
  ) async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        debugPrint('LiveLocationService note: Device GPS is disabled');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      await _emergencyRepository.updateUserEmergencyLocation(
        emergencyId: emergencyId,
        userId: userId,
        name: name,
        role: role,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      debugPrint('LiveLocationService: Published $role GPS (${position.latitude}, ${position.longitude}) for emergency $emergencyId');
    } catch (e) {
      debugPrint('LiveLocationService publish note: $e');
    }
  }

  /// Stops periodic location publishing immediately.
  void stopTracking() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      debugPrint('LiveLocationService: Stopped tracking for emergency $_activeEmergencyId');
    }
    _activeEmergencyId = null;
  }

  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }
    return true;
  }
}
