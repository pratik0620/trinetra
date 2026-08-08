import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';
import '../../shared/widgets/map_placeholder_widget.dart';

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
  int _secondsAgo = 18;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsAgo++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onRespond() async {
    final notifier = ref.read(mockStateProvider.notifier);
    notifier.respondToGuardianEmergency();

    final authUser = ref.read(authRepositoryProvider).currentUser;
    final emergencyRepo = ref.read(emergencyRepositoryProvider);

    final eId = widget.emergencyId ?? 'emergency_active_demo';
    final guardianUid = authUser?.uid ?? 'guardian_ananya';

    try {
      await emergencyRepo.respondToEmergency(
        emergencyId: eId,
        guardianUid: guardianUid,
      );
    } catch (e) {
      debugPrint('Firestore respond note: $e');
    }

    if (mounted) {
      context.push('/guardian-responding?emergencyId=$eId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Banner
            Container(
              color: AppColors.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'ACTIVE EMERGENCY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onErrorContainer,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Priya needs help',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: AppColors.onErrorContainer),
                      const SizedBox(width: 4),
                      Text(
                        'SOS triggered $_secondsAgo seconds ago',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Map Area
            const Expanded(
              child: MapPlaceholderWidget(
                isEmergencyMode: true,
                focusName: 'Priya',
                distanceText: '2.4 km',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 2x2 Info Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildInfoTile(
                          'Alert Type', 'Manual Stomp', AppColors.emergency),
                      _buildInfoTile(
                          'Status', 'SOS Active', AppColors.emergency),
                      _buildInfoTile(
                          'Location', 'Live Tracking', AppColors.onSurface),
                      _buildInfoTile(
                          'Communication', 'Via RAKSHA', AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Primary Action (Real Firestore Update)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _onRespond,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        "I'M RESPONDING",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Actions
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.call_rounded, size: 18),
                            label: const Text(
                              'CALL PRIYA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emergency,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.local_police_rounded,
                                size: 18),
                            label: const Text(
                              'CALL 112',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
