import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config/location_config.dart';
import '../repositories/emergency_repository.dart';

class PositionResult {
  final double latitude;
  final double longitude;
  final bool isFallback;
  final String source;

  const PositionResult({
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    required this.source,
  });
}

class LiveLocationService {
  final EmergencyRepository _emergencyRepository;
  Timer? _timer;
  String? _activeEmergencyId;

  LiveLocationService({EmergencyRepository? emergencyRepository})
      : _emergencyRepository = emergencyRepository ?? EmergencyRepository();

  /// Public permission check & request helper with detailed debug logs.
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LOCATION PERMISSION] Location services enabled: $serviceEnabled');

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[LOCATION PERMISSION] Initial status: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('[LOCATION PERMISSION] Requesting location permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('[LOCATION PERMISSION] Result after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LOCATION PERMISSION] ⚠️ Location permissions permanently denied.');
        return false;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('[LOCATION PERMISSION] ⚠️ Location permission denied by user.');
        return false;
      }

      final isGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      debugPrint('[LOCATION PERMISSION] 🟢 Location permission granted: $isGranted');
      return isGranted;
    } catch (e) {
      debugPrint('[LOCATION PERMISSION] Exception checking permissions: $e');
      return false;
    }
  }

  /// Attempts to acquire high-accuracy live GPS coordinates.
  /// If GPS is disabled, denied, or fails, gracefully falls back to configured environment fallback coordinates.
  Future<PositionResult> getCurrentPositionOrFallback() async {
    final hasPerm = await checkAndRequestPermission();
    if (hasPerm) {
      try {
        final isEnabled = await Geolocator.isLocationServiceEnabled();
        if (isEnabled) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          LocationConfig.logLocationStatus(
            latitude: position.latitude,
            longitude: position.longitude,
            isFallback: false,
            tag: 'GPS_ACQUISITION',
          );
          return PositionResult(
            latitude: position.latitude,
            longitude: position.longitude,
            isFallback: false,
            source: 'live_gps',
          );
        } else {
          debugPrint('[GPS_ACQUISITION] Device location services (GPS) are disabled on device.');
        }
      } catch (e) {
        debugPrint('[GPS_ACQUISITION] High accuracy GPS fix failed ($e), trying last known position...');
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            LocationConfig.logLocationStatus(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              isFallback: false,
              tag: 'GPS_ACQUISITION',
            );
            return PositionResult(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              isFallback: false,
              source: 'last_known_gps',
            );
          }
        } catch (_) {}
      }
    }

    final fallbackLat = LocationConfig.fallbackLatitude;
    final fallbackLng = LocationConfig.fallbackLongitude;
    LocationConfig.logLocationStatus(
      latitude: fallbackLat,
      longitude: fallbackLng,
      isFallback: true,
      tag: 'GPS_ACQUISITION',
    );
    return PositionResult(
      latitude: fallbackLat,
      longitude: fallbackLng,
      isFallback: true,
      source: 'fallback_config',
    );
  }

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

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      debugPrint('LiveLocationService note: Location permission denied. Tracking using fallback when needed.');
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
      final posResult = await getCurrentPositionOrFallback();

      if (role.toLowerCase() == 'victim') {
        debugPrint('====================================');
        debugPrint('VICTIM LOCATION:');
        debugPrint('lat=${posResult.latitude}');
        debugPrint('lon=${posResult.longitude}');
        debugPrint('emergencyId=$emergencyId');
        debugPrint('uid=$userId');
        debugPrint('====================================');
      } else {
        debugPrint('====================================');
        debugPrint('GUARDIAN LOCATION:');
        debugPrint('lat=${posResult.latitude}');
        debugPrint('lon=${posResult.longitude}');
        debugPrint('====================================');
      }

      await _emergencyRepository.updateUserEmergencyLocation(
        emergencyId: emergencyId,
        userId: userId,
        name: name,
        role: role,
        latitude: posResult.latitude,
        longitude: posResult.longitude,
        isFallback: posResult.isFallback,
      );

      debugPrint(
          'LiveLocationService: Published $role location (${posResult.latitude}, ${posResult.longitude}, isFallback=${posResult.isFallback}) for emergency $emergencyId');
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
}

