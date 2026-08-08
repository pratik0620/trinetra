import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/mock_state_provider.dart';
import '../../shared/widgets/map_placeholder_widget.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mockStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full Map Canvas
          const MapPlaceholderWidget(
            isEmergencyMode: false,
            focusName: 'Ananya',
            distanceText: '0.8 km',
          ),

          // Floating Map Controls (Right side)
          Positioned(
            right: 16,
            top: 70,
            child: Column(
              children: [
                _buildMapButton(Icons.layers_rounded),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      _buildMapIconButton(Icons.add_rounded),
                      const Divider(height: 1, color: AppColors.surfaceVariant),
                      _buildMapIconButton(Icons.remove_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildMapButton(Icons.my_location_rounded,
                    color: AppColors.primaryContainer),
              ],
            ),
          ),

          // Bottom Contact Sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceVariant),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(
                          state.peopleIProtect.first.avatarUrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.peopleIProtect.first.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.shield_rounded,
                                    size: 14, color: AppColors.tertiary),
                                SizedBox(width: 4),
                                Text(
                                  'Protected • Safe',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.surfaceVariant,
                        child: IconButton(
                          icon: const Icon(Icons.directions_rounded,
                              color: AppColors.onSurface),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last Update',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant)),
                              Text('Just now',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Battery',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant)),
                              Row(
                                children: [
                                  Icon(Icons.battery_full_rounded,
                                      size: 14, color: AppColors.tertiary),
                                  SizedBox(width: 4),
                                  Text('92%',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, {Color? color}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainer.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Icon(icon, color: AppColors.onSurface, size: 20),
    );
  }

  Widget _buildMapIconButton(IconData icon) {
    return IconButton(
      icon: Icon(icon, color: AppColors.onSurface, size: 20),
      onPressed: () {},
    );
  }
}
