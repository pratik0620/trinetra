import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';
import '../../providers/sensor_selectors.dart';
import '../../providers/ble_state_provider.dart';
import '../../shared/widgets/safety_status_card.dart';
import '../../shared/widgets/shoe_status_card.dart';
import '../../shared/widgets/sos_button.dart';
import '../emergency/guardian_notification_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _onSosTriggered(BuildContext context) async {
    final notifier = ref.read(mockStateProvider.notifier);
    notifier.triggerMySos();

    final authService = ref.read(authServiceProvider);
    final sessionUid = await authService.getLocalSessionUid();
    final activeUid = ref.read(activeUserUidProvider);
    final authUser = ref.read(authRepositoryProvider).currentUser;
    final emergencyRepo = ref.read(emergencyRepositoryProvider);

    final userId = activeUid ?? sessionUid ?? authUser?.uid ?? '';
    try {
      final emergencyId = await emergencyRepo.createEmergency(
        userId: userId,
        deviceId: 'device_raksha_shoe_01',
        triggerType: 'manual_sos',
      );

      debugPrint('====================================');
      debugPrint('SOS TRIGGERED');
      debugPrint('userId = $userId');
      debugPrint('emergencyId = $emergencyId');

      final userRepo = ref.read(userRepositoryProvider);
      final userProfile = await userRepo.getUserProfile(userId);
      debugPrint('EMERGENCY CONTACTS VERIFICATION:');
      debugPrint('emergency_contacts = ${userProfile?.emergencyContacts}');
      debugPrint('Cloud Function onEmergencyCreated will notify guardians');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('Firestore emergency creation note: $e');
    }

    if (mounted) {
      context.push('/my-sos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockStateProvider);
    final notifier = ref.read(mockStateProvider.notifier);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            data: (userProfile) {
                              final firstName = userProfile?.firstName.isNotEmpty == true
                                  ? userProfile!.firstName
                                  : (userProfile?.name.split(' ').first ?? 'User');
                              return Text(
                                'Good evening, $firstName',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              );
                            },
                            loading: () => const SizedBox(
                              width: 160,
                              height: 28,
                              child: LinearProgressIndicator(
                                color: AppColors.primaryContainer,
                              ),
                            ),
                            error: (_, __) => const Text(
                              'Good evening',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          notifier.triggerGuardianNotification();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                   // Safety Status Card
                  Consumer(
                    builder: (context, ref, child) {
                      final status = ref.watch(effectiveSafetyStatusProvider);
                      return SafetyStatusCard(status: status);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Smart Shoe Status Card Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Smart Shoe Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Smart Shoe Status Card
                  Consumer(
                    builder: (context, ref, child) {
                      final isConnected = ref.watch(effectiveShoeStatusProvider.select((s) => s.isConnected));
                      final batteryPercent = ref.watch(effectiveShoeStatusProvider.select((s) => s.batteryPercent));
                      final isBleConnected = ref.watch(effectiveShoeStatusProvider.select((s) => s.isBleConnected));
                      final isGpsAvailable = ref.watch(effectiveShoeStatusProvider.select((s) => s.isGpsAvailable));
                      final is4gConnected = ref.watch(effectiveShoeStatusProvider.select((s) => s.is4gConnected));
                      final lastSyncedText = ref.watch(effectiveShoeStatusProvider.select((s) => s.lastSyncedText));

                      final status = ShoeStatusModel(
                        isConnected: isConnected,
                        batteryPercent: batteryPercent,
                        isBleConnected: isBleConnected,
                        isGpsAvailable: isGpsAvailable,
                        is4gConnected: is4gConnected,
                        lastSyncedText: lastSyncedText,
                      );

                      return ShoeStatusCard(shoeStatus: status);
                    },
                  ),

                  const SizedBox(height: 28),

                  // Central SOS Hold Button (Creates Real Firestore Emergency)
                  Center(
                    child: SOSButton(
                      onTrigger: () => _onSosTriggered(context),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // People I Protect preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'People I Protect',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/people'),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Builder(
                    builder: (context) {
                      final firestoreConnectionsAsync =
                          ref.watch(userFirestoreConnectionsProvider);
                      final connections = firestoreConnectionsAsync.value ?? [];

                      if (connections.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No connections added yet. Tap "View all" to manage.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: connections.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final contact = connections[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.surfaceVariant),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryContainer,
                                    child: Text(
                                      contact.displayName.isNotEmpty
                                          ? contact.displayName[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.displayName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Connected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Incoming Guardian Notification Banner overlay if active
            if (state.guardianStage ==
                GuardianEmergencyStage.incomingNotification)
              const Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: GuardianNotificationBanner(),
              ),
          ],
        ),
      ),
    );
  }
}
