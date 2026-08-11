import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';

class EmergencyMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String focusName;
  final bool isEmergencyMode;

  const EmergencyMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.focusName = 'Victim',
    this.isEmergencyMode = true,
  });

  @override
  State<EmergencyMap> createState() => _EmergencyMapState();
}

class _EmergencyMapState extends State<EmergencyMap> {
  GoogleMapController? _mapController;

  bool get _hasValidLocation {
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
    if (_hasValidLocation &&
        _mapController != null &&
        (oldWidget.latitude != widget.latitude ||
            oldWidget.longitude != widget.longitude)) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.latitude!, widget.longitude!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidLocation) {
      return _buildLocationUnavailable();
    }

    final latLng = LatLng(widget.latitude!, widget.longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: latLng,
              zoom: 15.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: {
              Marker(
                markerId: const MarkerId('emergency_victim_marker'),
                position: latLng,
                infoWindow: InfoWindow(
                  title: "${widget.focusName}'s Location",
                  snippet: '🚨 Emergency Alert Signal',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
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

          // Header Overlay Tag
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
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
                  const SizedBox(width: 6),
                  Text(
                    '${widget.focusName.split(" ").first}\'s SOS Location',
                    style: const TextStyle(
                      fontSize: 12,
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
