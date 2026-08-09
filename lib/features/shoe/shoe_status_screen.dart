import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/ble_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/ble_state_provider.dart';
import '../../providers/sensor_selectors.dart';
import '../../shared/widgets/shoe_status_card.dart';

class ShoeStatusScreen extends ConsumerWidget {
  const ShoeStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);
    final sensorData = ref.watch(effectiveSensorProvider);
    final lastSyncedText = ref.watch(lastUpdateDisplayProvider);

    final connState = bleState.connectionState;
    final isLive = bleState.isLive;
    final battery = sensorData?.battery;
    final isConnected = connState == BleConnectionState.connected;

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Device Graphic & Connection status
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
                            color: (isConnected
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
                            color: isConnected
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
                              color: isConnected
                                  ? AppColors.tertiaryContainer.withOpacity(0.3)
                                  : AppColors.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isConnected
                                    ? AppColors.tertiary.withOpacity(0.3)
                                    : AppColors.emergency.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                LiveIndicator(isLive: isLive),
                                const SizedBox(width: 8),
                                Text(
                                  connState == BleConnectionState.connected
                                      ? 'Connected'
                                      : connState == BleConnectionState.connecting
                                          ? 'Connecting'
                                          : connState == BleConnectionState.scanning
                                              ? 'Scanning'
                                              : 'Disconnected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isConnected
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
                      'Last packet: $lastSyncedText',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Emergency Active Banner (if applicable)
              if (sensorData?.state == 'EMERGENCY') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.emergency),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_rounded, color: AppColors.emergency, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'EMERGENCY STATE ACTIVE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emergency,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SOS Signal transmitting. coordinates: '
                        'Lat: ${sensorData?.lat ?? 'Location unavailable'}, '
                        'Lon: ${sensorData?.lon ?? 'Location unavailable'}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Battery: ${battery != null ? "$battery%" : "--%"} | '
                        'Timestamp: ${sensorData?.timestamp != null ? sensorData!.timestamp.toLocal().toString().split('.').first : 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Bento Status Section (Battery & State)
              Row(
                children: [
                  Expanded(
                    child: _buildBentoTile(
                      icon: Icons.battery_full_rounded,
                      iconColor: AppColors.primary,
                      metric: battery != null ? '$battery%' : '--%',
                      title: 'Battery',
                      subtitle: battery != null && battery < 20 ? 'Battery Low' : 'Normal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoTile(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.tertiary,
                      metric: sensorData?.state ?? 'Unknown',
                      title: 'Shoe State',
                      subtitle: 'Active Mode',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Sensors Telemetry Card
              Text(
                'Shoe Sensors',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  children: [
                    _buildSensorRow(
                      icon: Icons.compress_rounded,
                      label: 'Heel Pressure (FSR)',
                      value: sensorData?.fsr != null ? '${sensorData!.fsr}' : '--',
                    ),
                    const Divider(height: 24, color: AppColors.outlineVariant),
                    _buildSensorRow(
                      icon: Icons.grid_3x3_rounded,
                      label: 'Acceleration (g)',
                      value: sensorData?.accel != null ? '${sensorData!.accel!.toStringAsFixed(2)} g' : '--',
                    ),
                    const Divider(height: 24, color: AppColors.outlineVariant),
                    _buildSensorRow(
                      icon: Icons.explore_rounded,
                      label: 'Gyroscope (deg/s)',
                      value: sensorData?.gyro != null ? '${sensorData!.gyro!.toStringAsFixed(1)} °/s' : '--',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. GPS Section
              Text(
                'GPS Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sensorData?.gpsFresh == true
                              ? Icons.gps_fixed_rounded
                              : Icons.gps_off_rounded,
                          color: sensorData?.gpsFresh == true
                              ? AppColors.tertiary
                              : AppColors.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sensorData?.gpsFresh == true
                              ? 'GPS Available'
                              : 'GPS Unavailable',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (sensorData?.gpsFresh == true) ...[
                      const SizedBox(height: 12),
                      _buildLocationField('Latitude', sensorData?.lat?.toString() ?? 'Location unavailable'),
                      const SizedBox(height: 8),
                      _buildLocationField('Longitude', sensorData?.lon?.toString() ?? 'Location unavailable'),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Location unavailable',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 6. Action Button (Connect / Disconnect)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (isConnected) {
                      ref.read(bleServiceProvider).disconnect();
                    } else {
                      ref.read(bleServiceProvider).startScan();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isConnected
                        ? AppColors.emergency
                        : AppColors.tertiary,
                    side: BorderSide(
                      color: isConnected
                          ? AppColors.errorContainer
                          : AppColors.tertiaryContainer,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  icon: Icon(
                    isConnected
                        ? Icons.link_off_rounded
                        : Icons.link_rounded,
                  ),
                  label: Text(
                    isConnected ? 'Disconnect Shoe' : 'Connect Shoe',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    required String metric,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              Text(
                metric,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildSensorRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
