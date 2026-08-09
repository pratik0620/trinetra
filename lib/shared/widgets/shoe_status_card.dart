import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../core/services/ble_service.dart';
import '../../providers/ble_state_provider.dart';
import '../../providers/sensor_selectors.dart';

class LiveIndicator extends StatefulWidget {
  final bool isLive;

  const LiveIndicator({super.key, required this.isLive});

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && _controller == null) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);
    } else if (!widget.isLive && _controller != null) {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary.withOpacity(
                    0.3 + 0.7 * _controller!.value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiary.withOpacity(
                        0.5 * _controller!.value,
                      ),
                      blurRadius: 4.0 * _controller!.value,
                      spreadRadius: 2.0 * _controller!.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.tertiary,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
  }
}

class ShoeStatusCard extends ConsumerWidget {
  final ShoeStatusModel shoeStatus;

  const ShoeStatusCard({
    super.key,
    required this.shoeStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final isLive = ref.watch(bleStateProvider.select((s) => s.isLive));
                        return LiveIndicator(isLive: isLive);
                      },
                    ),
                  ],
                ),
                // Battery Container (Nested Consumer for Rebuild Optimization)
                Consumer(
                  builder: (context, ref, child) {
                    final battery = ref.watch(effectiveSensorProvider.select((s) => s?.battery));
                    final connState = ref.watch(bleStateProvider.select((s) => s.connectionState));

                    Widget icon;
                    String text;
                    Color color;

                    if (connState == BleConnectionState.scanning) {
                      icon = const Icon(
                        Icons.battery_unknown_rounded,
                        size: 16,
                        color: Colors.grey,
                      );
                      text = '--%';
                      color = Colors.grey;
                    } else if (connState == BleConnectionState.connecting) {
                      icon = const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                      );
                      text = '--%';
                      color = Colors.grey;
                    } else {
                      final isConnected = connState == BleConnectionState.connected;
                      if (isConnected) {
                        final actualBattery = battery ?? 0;
                        text = '$actualBattery%';
                        if (actualBattery < 20) {
                          icon = const Icon(
                            Icons.battery_alert_rounded,
                            size: 16,
                            color: AppColors.emergency,
                          );
                          color = AppColors.emergency;
                        } else {
                          icon = const Icon(
                            Icons.battery_full_rounded,
                            size: 16,
                            color: AppColors.tertiary,
                          );
                          color = AppColors.tertiary;
                        }
                      } else {
                        // fallback to mock status battery
                        final mockBattery = shoeStatus.batteryPercent;
                        text = '$mockBattery%';
                        icon = const Icon(
                          Icons.battery_full_rounded,
                          size: 16,
                          color: AppColors.tertiary,
                        );
                        color = AppColors.tertiary;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          icon,
                          const SizedBox(width: 4),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
            // Telemetry Grid
            Consumer(
              builder: (context, ref, child) {
                final sensorData = ref.watch(effectiveSensorProvider);
                final fsr = sensorData?.fsr;
                final accel = sensorData?.accel;
                final gyro = sensorData?.gyro;

                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTelemetryCol(
                        label: 'FSR',
                        value: fsr != null ? '$fsr' : '--',
                      ),
                      _buildTelemetryCol(
                        label: 'Accel',
                        value: accel != null ? '${accel.toStringAsFixed(2)}g' : '--',
                      ),
                      _buildTelemetryCol(
                        label: 'Gyro',
                        value: gyro != null ? '${gyro.toStringAsFixed(1)}°/s' : '--',
                      ),
                      _buildTelemetryCol(
                        label: 'State',
                        value: sensorData?.state ?? 'Unknown',
                      ),
                    ],
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withOpacity(0.2),
                  ),
                ),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final lastSyncedText = ref.watch(lastUpdateDisplayProvider);
                  final connState = ref.watch(bleStateProvider.select((s) => s.connectionState));

                  Widget icon;
                  String text;

                  if (connState == BleConnectionState.scanning) {
                    icon = const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    );
                    text = 'Searching for shoe...';
                  } else if (connState == BleConnectionState.connecting) {
                    icon = const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    );
                    text = 'Connecting to shoe...';
                  } else {
                    final isConnected = connState == BleConnectionState.connected;
                    icon = Icon(
                      isConnected ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    );
                    text = isConnected
                        ? 'Connected - Last sync: $lastSyncedText'
                        : 'Shoe Disconnected - Tap to reconnect';
                  }

                  return Row(
                    children: [
                      icon,
                      const SizedBox(width: 4),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCol({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
