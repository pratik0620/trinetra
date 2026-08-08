import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';
import '../../shared/widgets/map_placeholder_widget.dart';

class GuardianEmergencyRespondingScreen extends ConsumerWidget {
  final String? emergencyId;

  const GuardianEmergencyRespondingScreen({
    super.key,
    this.emergencyId,
  });

  void _onResolve(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(mockStateProvider.notifier);
    notifier.resolveGuardianEmergency();

    final emergencyRepo = ref.read(emergencyRepositoryProvider);
    final eId = emergencyId ?? 'emergency_active_demo';

    try {
      await emergencyRepo.resolveEmergency(eId);
    } catch (e) {
      debugPrint('Firestore resolve note: $e');
    }

    if (context.mounted) {
      context.push('/guardian-resolved?emergencyId=$eId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Banner
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(color: AppColors.tertiary, width: 3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 36,
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'YOU ARE RESPONDING',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Priya's emergency is being handled.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Content Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Acknowledgment Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: AppColors.primary, width: 4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_rounded,
                              color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Response acknowledged. Other RAKSHA contacts can see that you are responding.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Map
                    const Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        child: MapPlaceholderWidget(
                          isEmergencyMode: true,
                          focusName: 'Priya',
                          distanceText: '1.2 km',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text(
                        'NAVIGATE',
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
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {},
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
                            label: const Text('CALL PRIYA'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorContainer,
                              foregroundColor: AppColors.onErrorContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.emergency_rounded, size: 18),
                            label: const Text('CALL 112'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Resolve Action
                  TextButton.icon(
                    onPressed: () => _onResolve(context, ref),
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.tertiary, size: 18),
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
            ),
          ],
        ),
      ),
    );
  }
}
