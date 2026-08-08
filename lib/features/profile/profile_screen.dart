import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/mock_state_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _emergencyAlertsToggle = true;
  bool _safetyAlertsToggle = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockStateProvider);
    final user = state.currentUser;
    final shoe = state.shoeStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          child: Column(
            children: [
              // Avatar & Profile Info
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primaryContainer, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(user.avatarUrl),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryContainer,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.onPrimaryContainer),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.surfaceVariant),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.group_rounded,
                                    color: AppColors.primary, size: 20),
                                SizedBox(height: 4),
                                Text(
                                  '3',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Connections',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.surfaceVariant),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  shoe.isConnected
                                      ? Icons.bluetooth_connected_rounded
                                      : Icons.bluetooth_disabled_rounded,
                                  color: shoe.isConnected
                                      ? AppColors.tertiary
                                      : AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  shoe.isConnected
                                      ? '${shoe.batteryPercent}%'
                                      : 'Off',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: shoe.isConnected
                                        ? AppColors.tertiary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  shoe.isConnected
                                      ? 'Shoe Active'
                                      : 'Disconnected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: shoe.isConnected
                                        ? AppColors.tertiary
                                        : AppColors.onSurfaceVariant,
                                  ),
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

              const SizedBox(height: 28),

              // Settings Sections
              _buildSettingsGroup(
                title: 'Emergency',
                items: [
                  _SettingsItem(
                    icon: Icons.contacts_rounded,
                    title: 'Contacts',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.sos_rounded,
                    iconColor: AppColors.emergency,
                    title: 'SOS Settings',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Alert Settings',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSettingsGroup(
                title: 'Location',
                items: [
                  _SettingsItem(
                    icon: Icons.location_on_rounded,
                    title: 'Sharing',
                    badge: 'Active',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Permissions',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSettingsGroup(
                title: 'Shoe',
                items: [
                  _SettingsItem(
                    icon: Icons.devices_other_rounded,
                    iconColor: shoe.isConnected ? AppColors.tertiary : null,
                    title: 'Connected device',
                    subtitle: shoe.isConnected
                        ? 'RAKSHA Shoe - ${shoe.batteryPercent}% Battery'
                        : 'Shoe Disconnected',
                    onTap: () => context.push('/shoe-status'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notifications Group
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        'NOTIFICATIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      value: _emergencyAlertsToggle,
                      activeColor: AppColors.primary,
                      title: const Text('Emergency alerts',
                          style: TextStyle(
                              color: AppColors.onSurface, fontSize: 15)),
                      secondary: const Icon(Icons.campaign_rounded,
                          color: AppColors.onSurfaceVariant),
                      onChanged: (val) =>
                          setState(() => _emergencyAlertsToggle = val),
                    ),
                    const Divider(height: 1, color: AppColors.surfaceVariant),
                    SwitchListTile(
                      value: _safetyAlertsToggle,
                      activeColor: AppColors.primary,
                      title: const Text('Safety alerts',
                          style: TextStyle(
                              color: AppColors.onSurface, fontSize: 15)),
                      secondary: const Icon(Icons.health_and_safety_rounded,
                          color: AppColors.onSurfaceVariant),
                      onChanged: (val) =>
                          setState(() => _safetyAlertsToggle = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Log Out Button
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emergency,
                  side: const BorderSide(color: AppColors.errorContainer),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Log Out',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == items.length - 1;

            return Column(
              children: [
                ListTile(
                  onTap: item.onTap,
                  leading: Icon(
                    item.icon,
                    color: item.iconColor ?? AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, color: AppColors.surfaceVariant),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    required this.onTap,
  });
}
