import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/emergency_location_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import 'widgets/emergency_map.dart';

class GuardianEmergencyActiveScreen extends ConsumerStatefulWidget {
  final String? emergencyId;

  const GuardianEmergencyActiveScreen({
    super.key,
    this.emergencyId,
  });

  @override
  ConsumerState<GuardianEmergencyActiveScreen> createState() =>
      _GuardianEmergencyActiveScreenState();
}

class _GuardianEmergencyActiveScreenState
    extends ConsumerState<GuardianEmergencyActiveScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  UserModel? _victimProfile;
  bool _isGuardianTrackingStarted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Stop guardian location updates when leaving the screen
    ref.read(liveLocationServiceProvider).stopTracking();
    super.dispose();
  }

  void _loadVictimProfile(String victimUid) async {
    if (_victimProfile != null || victimUid.isEmpty) return;
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final profile = await userRepo.getUserProfile(victimUid);
      if (profile != null && mounted) {
        setState(() => _victimProfile = profile);
      }
    } catch (_) {}
  }

  void _startGuardianLiveLocation(String eId) {
    if (_isGuardianTrackingStarted) return;
    _isGuardianTrackingStarted = true;

    final activeUid = ref.read(activeUserUidProvider);
    final authUser = ref.read(authRepositoryProvider).currentUser;
    final guardianUid = activeUid ?? authUser?.uid ?? 'guardian_user';

    final userProfile = ref.read(currentUserProfileProvider).value;
    final guardianName = userProfile?.displayName ?? 'Guardian';

    ref.read(liveLocationServiceProvider).startTracking(
          emergencyId: eId,
          userId: guardianUid,
          name: guardianName,
          role: 'guardian',
        );
  }

  void _onRespond(String eId) async {
    final activeUid = ref.read(activeUserUidProvider);
    final authUser = ref.read(authRepositoryProvider).currentUser;
    final guardianUid = activeUid ?? authUser?.uid ?? 'guardian_user';

    final emergencyRepo = ref.read(emergencyRepositoryProvider);
    await emergencyRepo.respondToEmergency(
      emergencyId: eId,
      guardianUid: guardianUid,
    );

    _startGuardianLiveLocation(eId);
  }

  void _onResolve(String eId) async {
    // Stop guardian tracking upon emergency resolution
    ref.read(liveLocationServiceProvider).stopTracking();

    final emergencyRepo = ref.read(emergencyRepositoryProvider);
    await emergencyRepo.resolveEmergency(eId);
  }

  Future<void> _launchCall(String? rawPhone) async {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available for this contact'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to make call: $cleanPhone'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launch112() async {
    final uri = Uri.parse('tel:112');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  /// Fixes "OPEN IN MAPS" to launch exact live victim coordinates.
  Future<void> _launchMaps(double? lat, double? lng, {bool isFallback = false}) async {
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Victim location coordinates unavailable'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final googleMapsUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    debugPrint('==================================================');
    debugPrint('OPEN IN MAPS VERIFICATION: lat=$lat, lng=$lng');
    debugPrint('Location Type: ${isFallback ? "FALLBACK (GPS unavailable)" : "LIVE GPS"}');
    debugPrint('Launching URL: $googleMapsUri');
    debugPrint('==================================================');

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isFallback ? "Fallback Location" : "Location"}: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTriggerType(String rawType) {
    switch (rawType.toLowerCase()) {
      case 'shoe':
      case 'smart_shoe':
        return 'Smart Shoe';
      case 'stomp':
        return 'Stomp Gesture';
      case 'fall':
        return 'Fall Detected';
      case 'sms':
        return 'SMS Alert';
      case 'manual_sos':
      default:
        return 'Manual SOS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eId = widget.emergencyId ?? 'emergency_active_demo';
    final emergencyAsync = ref.watch(singleEmergencyUnifiedProvider(eId));
    final emergency = emergencyAsync.value;

    final locationsAsync = ref.watch(emergencyLocationsProvider(eId));
    final liveLocations = locationsAsync.value ?? [];

    if (emergency != null && emergency.userId.isNotEmpty) {
      _loadVictimProfile(emergency.userId);
    }

    final status = (emergency?.status ?? 'active').toLowerCase();
    final isResponding = status == 'responding' || status == 'acknowledged';
    final isResolved = status == 'resolved' || status == 'cancelled';

    // Start guardian live location tracking if viewing active/responding emergency
    if (!isResolved && !_isGuardianTrackingStarted) {
      _startGuardianLiveLocation(eId);
    }

    // Determine Single Source of Truth for Victim Location
    EmergencyLocationModel? victimLocationDoc;
    try {
      victimLocationDoc = liveLocations.firstWhere(
        (l) => l.isVictim && l.latitude != 0.0 && l.longitude != 0.0,
      );
    } catch (_) {}

    final victimLat = victimLocationDoc?.latitude ?? emergency?.latitude;
    final victimLng = victimLocationDoc?.longitude ?? emergency?.longitude;
    final isLocationFallback = (victimLocationDoc?.isFallback ?? emergency?.isFallback) ?? false;

    final hasVictimLocation = victimLat != null &&
        victimLng != null &&
        (victimLat != 0.0 || victimLng != 0.0);

    if (hasVictimLocation) {
      debugPrint('[GUARDIAN SCREEN] Displaying ${isLocationFallback ? "FALLBACK" : "LIVE GPS"} victim location: ($victimLat, $victimLng)');
    }

    String victimName = 'RAKSHA Victim';
    if (victimLocationDoc != null && victimLocationDoc.name.isNotEmpty && victimLocationDoc.name != 'Victim') {
      victimName = victimLocationDoc.name;
    } else if (emergency?.userName.isNotEmpty == true && emergency?.userName != 'RAKSHA Contact') {
      victimName = emergency!.userName;
    } else if (_victimProfile != null && _victimProfile!.name.isNotEmpty) {
      victimName = _victimProfile!.name;
    }

    final victimPhone = emergency?.phoneNumber ?? _victimProfile?.phone;
    final triggerText = _formatTriggerType(emergency?.triggerType ?? 'manual_sos');
    final formattedTime = emergency?.timestamp != null
        ? DateFormat('h:mm a').format(emergency!.timestamp)
        : DateFormat('h:mm a').format(DateTime.now());

    final timeDiff = emergency?.timestamp != null
        ? DateTime.now().difference(emergency!.timestamp).inSeconds
        : _elapsedSeconds;
    final displaySeconds = timeDiff > 0 ? timeDiff : _elapsedSeconds;

    // Calculate Location Age & Fallback Status
    String ageText = isLocationFallback ? '⚠ Fallback location (GPS unavailable)' : 'Updated just now';
    bool isStaleLocation = isLocationFallback;
    if (victimLocationDoc != null && !isLocationFallback) {
      final sec = victimLocationDoc.secondsAgo;
      isStaleLocation = victimLocationDoc.isStale;
      ageText = isStaleLocation ? '⚠ Updated ${sec}s ago' : 'Updated ${sec}s ago';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onBackground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          isResolved
              ? 'EMERGENCY RESOLVED'
              : (isResponding ? 'RESPONDING TO SOS' : 'ACTIVE SOS ALERT'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Emergency Status Banner
            Container(
              width: double.infinity,
              color: isResolved
                  ? AppColors.tertiaryContainer.withOpacity(0.4)
                  : (isResponding
                      ? AppColors.surfaceContainerHigh
                      : AppColors.errorContainer),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isResolved
                            ? Icons.check_circle_rounded
                            : (isResponding
                                ? Icons.shield_rounded
                                : Icons.warning_amber_rounded),
                        color: isResolved
                            ? AppColors.tertiary
                            : (isResponding ? AppColors.primary : AppColors.error),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isResolved
                            ? 'RESOLVED'
                            : (isResponding ? 'RESPONDING' : 'ACTIVE EMERGENCY'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isResolved
                              ? AppColors.tertiary
                              : (isResponding
                                  ? AppColors.primary
                                  : AppColors.onErrorContainer),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      if (emergency?.isOfflineData == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Offline Alert',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isResolved
                        ? 'Emergency marked as resolved'
                        : (isResponding
                            ? 'You are responding to $victimName'
                            : '$victimName needs immediate help'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isResolved
                          ? AppColors.onBackground
                          : (isResponding
                              ? AppColors.onBackground
                              : AppColors.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isResolved
                            ? AppColors.onSurfaceVariant
                            : (isResponding
                                ? AppColors.onSurfaceVariant
                                : AppColors.onErrorContainer),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Triggered $displaySeconds seconds ago ($formattedTime)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isResolved
                              ? AppColors.onSurfaceVariant
                              : (isResponding
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.onErrorContainer),
                        ),
                      ),
                      const Spacer(),
                      if (hasVictimLocation)
                        Text(
                          ageText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isStaleLocation ? AppColors.error : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Embedded Google Map
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: EmergencyMap(
                  latitude: victimLat,
                  longitude: victimLng,
                  focusName: victimName,
                  isEmergencyMode: true,
                  liveLocations: liveLocations,
                ),
              ),
            ),

            // Bottom Action Panel
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 2x2 Emergency Details Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildInfoTile(
                          'Triggered By', triggerText, AppColors.emergency),
                      _buildInfoTile(
                          'Status', status.toUpperCase(), AppColors.primary),
                      _buildInfoTile(
                        'Victim Location',
                        hasVictimLocation
                            ? '${victimLat.toStringAsFixed(4)}, ${victimLng.toStringAsFixed(4)}'
                            : 'Unavailable',
                        hasVictimLocation ? AppColors.onSurface : AppColors.error,
                      ),
                      _buildInfoTile(
                          'GPS Update', ageText, isStaleLocation ? AppColors.error : AppColors.onSurface),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // State-dependent Primary Action Buttons
                  if (isResolved)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer,
                          foregroundColor: AppColors.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text(
                          'RETURN TO HOME',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (!isResponding)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _onRespond(eId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                        ),
                        icon: const Icon(Icons.shield_rounded, size: 22),
                        label: const Text(
                          "I'M RESPONDING",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: hasVictimLocation
                                ? () => _launchMaps(victimLat, victimLng, isFallback: isLocationFallback)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.navigation_rounded),
                            label: const Text(
                              'OPEN IN MAPS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _launchCall(victimPhone),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.onSurface,
                                    side: const BorderSide(
                                        color: AppColors.outlineVariant),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.call_rounded,
                                      size: 18, color: AppColors.primary),
                                  label: Text(
                                    'CALL ${victimName.split(" ").first.toUpperCase()}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _launch112,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.errorContainer,
                                    foregroundColor: AppColors.onErrorContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.emergency_rounded,
                                      size: 18),
                                  label: const Text(
                                    'CALL 112',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _onResolve(eId),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.tertiary,
                            size: 18,
                          ),
                          label: const Text(
                            'MARK AS RESOLVED',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
