import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';

class MyEmergencyScreen extends ConsumerStatefulWidget {
  const MyEmergencyScreen({super.key});

  @override
  ConsumerState<MyEmergencyScreen> createState() => _MyEmergencyScreenState();
}

class _MyEmergencyScreenState extends ConsumerState<MyEmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;
  int _seconds = 12;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVictimLiveLocation();
    });
  }

  void _startVictimLiveLocation() {
    final activeUid = ref.read(activeUserUidProvider);
    final authUser = ref.read(authRepositoryProvider).currentUser;
    final victimUid = activeUid ?? authUser?.uid ?? 'victim_user';

    final userProfile = ref.read(currentUserProfileProvider).value;
    final victimName = userProfile?.displayName ?? 'Priya';

    final activeEmergency = ref.read(userActiveEmergencyProvider).value;
    final eId = activeEmergency?.id ?? 'emergency_active_demo';

    ref.read(liveLocationServiceProvider).startTracking(
          emergencyId: eId,
          userId: victimUid,
          name: victimName,
          role: 'victim',
        );
  }

  @override
  void dispose() {
    ref.read(liveLocationServiceProvider).stopTracking();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.errorContainer,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Pulsing Ring Waves
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 150 * _pulseAnimation.value,
                height: 150 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergency.withOpacity(
                    (2.0 - _pulseAnimation.value).clamp(0.0, 0.4),
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Alert Icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.emergency,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error,
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      size: 56,
                      color: AppColors.onError,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'SOS ACTIVE',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timer Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.emergency.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.emergency.withOpacity(0.4)),
                    ),
                    child: Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // System Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.emergency.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monitor_heart_rounded,
                                color: AppColors.error, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'SYSTEM STATUS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow('Location acquired'),
                        _buildStatusRow('Emergency contacts notified'),
                        _buildStatusRow('BLE notification sent'),
                        _buildStatusRow('SMS Sent'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dialing 112 Emergency Services...'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.onErrorContainer,
                        foregroundColor: AppColors.errorContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                      ),
                      icon: const Icon(Icons.call_rounded, size: 28),
                      label: const Text(
                        'CALL 112',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(liveLocationServiceProvider).stopTracking();
                        ref.read(mockStateProvider.notifier).cancelMySos();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: const BorderSide(color: AppColors.surfaceVariant, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'CANCEL SOS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.tertiaryFixed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
