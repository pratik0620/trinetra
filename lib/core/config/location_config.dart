import 'package:flutter/foundation.dart';

/// Configuration loader for fallback location coordinates.
/// Coordinates are loaded securely from environment / secrets configuration at runtime.
/// NEVER hardcode coordinates in Dart source code.
class LocationConfig {
  static const String _envLatStr = String.fromEnvironment('FALLBACK_LAT', defaultValue: '');
  static const String _envLngStr = String.fromEnvironment('FALLBACK_LNG', defaultValue: '');

  /// Returns fallback latitude loaded from environment runtime configuration.
  static double get fallbackLatitude {
    if (_envLatStr.isNotEmpty) {
      final parsed = double.tryParse(_envLatStr);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  /// Returns fallback longitude loaded from environment runtime configuration.
  static double get fallbackLongitude {
    if (_envLngStr.isNotEmpty) {
      final parsed = double.tryParse(_envLngStr);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  /// Checks whether developer-provided fallback coordinates are configured.
  static bool get hasFallbackConfigured {
    final lat = fallbackLatitude;
    final lng = fallbackLongitude;
    return (lat != 0.0 || lng != 0.0) && lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
  }

  /// Logs whether the location in use is LIVE GPS or FALLBACK.
  static void logLocationStatus({
    required double latitude,
    required double longitude,
    required bool isFallback,
    String tag = 'LOCATION_SYSTEM',
  }) {
    if (isFallback) {
      debugPrint('[$tag] ⚠️ GPS UNAVAILABLE. Using FALLBACK location: ($latitude, $longitude)');
    } else {
      debugPrint('[$tag] 🟢 Using LIVE GPS location: ($latitude, $longitude)');
    }
  }
}
