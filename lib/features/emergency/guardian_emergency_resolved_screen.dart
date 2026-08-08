import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/mock_state_provider.dart';

class GuardianEmergencyResolvedScreen extends ConsumerWidget {
  const GuardianEmergencyResolvedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mockStateProvider);
    final notifier = ref.read(mockStateProvider.notifier);
    final session = state.guardianSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Header
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.tertiary.withOpacity(0.15),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'EMERGENCY RESOLVED',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${session.victimName}'s SOS has ended.",
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Incident Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSummaryRow(
                      icon: Icons.directions_run_rounded,
                      label: 'TRIGGER',
                      value: session.triggerType,
                    ),
                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      icon: Icons.timer_outlined,
                      label: 'DURATION',
                      value: session.durationText,
                    ),
                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      icon: Icons.person_outline_rounded,
                      label: 'RESPONSE',
                      value: session.responderName,
                    ),
                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      icon: Icons.location_on_outlined,
                      label: 'FINAL LOCATION',
                      value: session.locationText,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    notifier.dismissGuardianEmergency();
                    context.go('/history');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text(
                    'VIEW EVENT DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    notifier.dismissGuardianEmergency();
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: const Text(
                    'RETURN TO DASHBOARD',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.outline, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
