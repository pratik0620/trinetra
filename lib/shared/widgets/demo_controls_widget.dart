import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/mock_state_provider.dart';

class DemoControlsFloatingWidget extends ConsumerWidget {
  const DemoControlsFloatingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 60,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDemoDialog(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bug_report_rounded,
                  size: 16,
                  color: AppColors.onPrimaryContainer,
                ),
                SizedBox(width: 4),
                Text(
                  'Demo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDemoDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(mockStateProvider);
    final notifier = ref.read(mockStateProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.developer_mode_rounded,
                        color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'RAKSHA Demo State Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Shoe Toggle
                ListTile(
                  leading: const Icon(Icons.directions_run_rounded,
                      color: AppColors.primary),
                  title: const Text('Smart Shoe Connection',
                      style: TextStyle(color: AppColors.onSurface)),
                  subtitle: Text(
                    state.shoeStatus.isConnected
                        ? 'Connected (84% battery)'
                        : 'Disconnected',
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  trailing: Switch(
                    value: state.shoeStatus.isConnected,
                    onChanged: (_) {
                      notifier.toggleShoeConnection();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const Divider(color: AppColors.outlineVariant),

                // Safety Status Selector
                const Text(
                  'Safety State (Home)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tertiaryContainer,
                          foregroundColor: AppColors.onTertiaryContainer,
                        ),
                        onPressed: () {
                          notifier.setSafetyStatus(SafetyStatusEnum.safe);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Safe'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warningContainer,
                          foregroundColor: AppColors.onWarningContainer,
                        ),
                        onPressed: () {
                          notifier.setSafetyStatus(SafetyStatusEnum.warning);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Warning'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorContainer,
                          foregroundColor: AppColors.onErrorContainer,
                        ),
                        onPressed: () {
                          notifier.setSafetyStatus(SafetyStatusEnum.emergency);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Emergency'),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.outlineVariant),

                // Trigger Flows
                const Text(
                  'Emergency Flows',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),

                // My SOS
                ListTile(
                  leading: const Icon(Icons.emergency_rounded,
                      color: AppColors.secondaryContainer),
                  title: const Text('Trigger My SOS',
                      style: TextStyle(color: AppColors.onSurface)),
                  subtitle: const Text('Navigates to SOS Active takeover screen',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                  onTap: () {
                    notifier.triggerMySos();
                    Navigator.pop(ctx);
                    context.push('/my-sos');
                  },
                ),

                // Incoming Guardian SOS
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.warning),
                  title: const Text('Simulate Incoming Guardian SOS',
                      style: TextStyle(color: AppColors.onSurface)),
                  subtitle: const Text('Triggers Priya SOS notification banner',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                  onTap: () {
                    notifier.triggerGuardianNotification();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
