import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';

class ShoeStatusCard extends StatelessWidget {
  final ShoeStatusModel shoeStatus;

  const ShoeStatusCard({
    super.key,
    required this.shoeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/shoe-status'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_run_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RAKSHA Shoe',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        shoeStatus.isConnected
                            ? Icons.battery_full_rounded
                            : Icons.battery_alert_rounded,
                        size: 16,
                        color: shoeStatus.isConnected
                            ? AppColors.tertiary
                            : AppColors.emergency,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shoeStatus.isConnected
                            ? '${shoeStatus.batteryPercent}%'
                            : 'Off',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(
                  icon: Icons.bluetooth_rounded,
                  label: 'BLE',
                  isActive: shoeStatus.isBleConnected,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  icon: Icons.location_on_rounded,
                  label: 'GPS',
                  isActive: shoeStatus.isGpsAvailable,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  icon: Icons.cell_tower_rounded,
                  label: '4G',
                  isActive: shoeStatus.is4gConnected,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    shoeStatus.isConnected
                        ? Icons.sync_rounded
                        : Icons.sync_disabled_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shoeStatus.isConnected
                        ? 'Connected - Last sync: ${shoeStatus.lastSyncedText}'
                        : 'Shoe Disconnected - Tap to reconnect',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
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

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
