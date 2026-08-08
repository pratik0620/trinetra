import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/mock_state_provider.dart';

class ShoeStatusScreen extends ConsumerWidget {
  const ShoeStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mockStateProvider);
    final notifier = ref.read(mockStateProvider.notifier);
    final shoe = state.shoeStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'RAKSHA SHOE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Hero Device Graphic
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse background circle
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (shoe.isConnected
                                    ? AppColors.tertiary
                                    : AppColors.emergency)
                                .withOpacity(0.08),
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceContainer,
                            border: Border.all(color: AppColors.surfaceVariant),
                          ),
                          child: Icon(
                            Icons.directions_run_rounded,
                            size: 64,
                            color: shoe.isConnected
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                        // Badge
                        Positioned(
                          bottom: 0,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: shoe.isConnected
                                  ? AppColors.tertiaryContainer
                                  : AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: shoe.isConnected
                                    ? AppColors.tertiary.withOpacity(0.3)
                                    : AppColors.emergency.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: shoe.isConnected
                                        ? AppColors.tertiary
                                        : AppColors.emergency,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  shoe.isConnected
                                      ? 'Connected'
                                      : 'Disconnected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: shoe.isConnected
                                        ? AppColors.onTertiaryContainer
                                        : AppColors.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last synced: ${shoe.lastSyncedText}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Status Bento Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    // Battery
                    _buildBentoTile(
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: AppColors.primary,
                      metric: shoe.isConnected ? '${shoe.batteryPercent}%' : 'Off',
                      title: 'Battery',
                      subtitle: shoe.isConnected
                          ? 'Charging (Est. 20m)'
                          : 'Depleted',
                    ),
                    // Bluetooth
                    _buildBentoTile(
                      icon: Icons.bluetooth_rounded,
                      iconColor: shoe.isBleConnected
                          ? AppColors.tertiary
                          : AppColors.outline,
                      statusIcon: shoe.isBleConnected
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      statusIconColor: shoe.isBleConnected
                          ? AppColors.tertiary
                          : AppColors.outline,
                      title: 'Bluetooth',
                      subtitle: shoe.isBleConnected
                          ? 'Signal Strong'
                          : 'Disconnected',
                    ),
                    // Location
                    _buildBentoTile(
                      icon: Icons.my_location_rounded,
                      iconColor: shoe.isGpsAvailable
                          ? AppColors.primary
                          : AppColors.outline,
                      statusIcon: shoe.isGpsAvailable
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      statusIconColor: shoe.isGpsAvailable
                          ? AppColors.tertiary
                          : AppColors.outline,
                      title: 'Location',
                      subtitle: shoe.isGpsAvailable
                          ? 'GPS Available'
                          : 'Unavailable',
                    ),
                    // 4G Network
                    _buildBentoTile(
                      icon: Icons.cell_tower_rounded,
                      iconColor: shoe.is4gConnected
                          ? AppColors.primary
                          : AppColors.outline,
                      metric: 'LTE',
                      title: 'Network',
                      subtitle: shoe.is4gConnected
                          ? '4G Connected'
                          : 'No Signal',
                    ),
                  ],
                ),
              ),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Testing Smart Shoe connection & sensors...'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  icon: const Icon(Icons.sensors_rounded),
                  label: const Text(
                    'Test Connection',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    notifier.toggleShoeConnection();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: shoe.isConnected
                        ? AppColors.emergency
                        : AppColors.tertiary,
                    side: BorderSide(
                      color: shoe.isConnected
                          ? AppColors.errorContainer
                          : AppColors.tertiaryContainer,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  icon: Icon(
                    shoe.isConnected
                        ? Icons.link_off_rounded
                        : Icons.link_rounded,
                  ),
                  label: Text(
                    shoe.isConnected ? 'Disconnect Shoe' : 'Connect Shoe',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoTile({
    required IconData icon,
    required Color iconColor,
    String? metric,
    IconData? statusIcon,
    Color? statusIconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              if (metric != null)
                Text(
                  metric,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                )
              else if (statusIcon != null)
                Icon(statusIcon, color: statusIconColor, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
