import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/location_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/emergency_location_model.dart';


class EmergencyMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String focusName;
  final bool isEmergencyMode;
  final List<EmergencyLocationModel>? liveLocations;

  const EmergencyMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.focusName = 'Victim',
    this.isEmergencyMode = true,
    this.liveLocations,
  });

  @override
  State<EmergencyMap> createState() => _EmergencyMapState();
}

class _EmergencyMapState extends State<EmergencyMap> {
  GoogleMapController? _mapController;
  bool _hasFitInitialBounds = false;

  bool get _hasValidLocation {
    if (widget.liveLocations != null && widget.liveLocations!.isNotEmpty) {
      return widget.liveLocations!.any((l) =>
          l.latitude != 0.0 &&
          l.longitude != 0.0 &&
          l.latitude >= -90 &&
          l.latitude <= 90 &&
          l.longitude >= -180 &&
          l.longitude <= 180);
    }
    if (widget.latitude == null || widget.longitude == null) return false;
    final lat = widget.latitude!;
    final lng = widget.longitude!;
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) return false;
    return true;
  }

  @override
  void didUpdateWidget(covariant EmergencyMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only auto-fit bounds on initial load, do not override manual camera panning on every 5s update
    if (!_hasFitInitialBounds && _mapController != null && _hasValidLocation) {
      _fitMapBounds();
      _hasFitInitialBounds = true;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.liveLocations != null && widget.liveLocations!.isNotEmpty) {
      for (final loc in widget.liveLocations!) {
        if (loc.latitude == 0.0 && loc.longitude == 0.0) continue;

        final position = LatLng(loc.latitude, loc.longitude);
        final markerId = MarkerId('location_${loc.role}_${loc.userId}');
        final isVictim = loc.isVictim;
        final ageText = loc.isStale ? '⚠ Updated ${loc.secondsAgo}s ago' : 'Updated ${loc.secondsAgo}s ago';

        markers.add(
          Marker(
            markerId: markerId,
            position: position,
            infoWindow: InfoWindow(
              title: '${loc.name} (${isVictim ? 'Victim 🔴' : 'Guardian 🔵'})',
              snippet: ageText,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isVictim ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }
    }

    // Fallback marker if liveLocations empty but latitude/longitude prop valid
    if (markers.isEmpty && widget.latitude != null && widget.longitude != null) {
      final fallbackPos = LatLng(widget.latitude!, widget.longitude!);
      markers.add(
        Marker(
          markerId: const MarkerId('emergency_fallback_victim'),
          position: fallbackPos,
          infoWindow: InfoWindow(
            title: "${widget.focusName}'s Location",
            snippet: '🚨 Emergency SOS Signal',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    return markers;
  }

  LatLng _getInitialTarget() {
    if (widget.liveLocations != null && widget.liveLocations!.isNotEmpty) {
      final victimLoc = widget.liveLocations!.firstWhere(
        (l) => l.isVictim && l.latitude != 0.0 && l.longitude != 0.0,
        orElse: () => widget.liveLocations!.first,
      );
      if (victimLoc.latitude != 0.0 && victimLoc.longitude != 0.0) {
        return LatLng(victimLoc.latitude, victimLoc.longitude);
      }
    }
    if (widget.latitude != null && widget.longitude != null) {
      return LatLng(widget.latitude!, widget.longitude!);
    }
    return LatLng(LocationConfig.fallbackLatitude, LocationConfig.fallbackLongitude);
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final markers = _buildMarkers();
    if (markers.isEmpty) return;

    if (markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 15.5),
      );
    } else {
      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (final m in markers) {
        if (m.position.latitude < minLat) minLat = m.position.latitude;
        if (m.position.latitude > maxLat) maxLat = m.position.latitude;
        if (m.position.longitude < minLng) minLng = m.position.longitude;
        if (m.position.longitude > maxLng) maxLng = m.position.longitude;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidLocation) {
      return _buildLocationUnavailable();
    }

    final initialTarget = _getInitialTarget();
    final markers = _buildMarkers();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapBounds();
              _hasFitInitialBounds = true;
            },
            markers: markers,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: true,
          ),

          // Header Overlay Badge Legend
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Victim',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Guardian',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUnavailable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Location unavailable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No valid GPS coordinates provided in alert payload',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
