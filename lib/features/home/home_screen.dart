import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';
import '../../shared/widgets/person_card.dart';
import '../../shared/widgets/safety_status_card.dart';
import '../../shared/widgets/shoe_status_card.dart';
import '../../shared/widgets/sos_button.dart';
import '../emergency/guardian_notification_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _onSosTriggered(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(mockStateProvider.notifier);
    notifier.triggerMySos();

    final authUser = ref.read(authRepositoryProvider).currentUser;
    final emergencyRepo = ref.read(emergencyRepositoryProvider);

    final userId = authUser?.uid ?? 'user_custom';
    try {
      await emergencyRepo.createEmergency(
        userId: userId,
        deviceId: 'device_raksha_shoe_01',
        triggerType: 'manual_sos',
      );
    } catch (e) {
      debugPrint('Firestore emergency creation note: $e');
    }

    if (context.mounted) {
      context.push('/my-sos');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  SafetyStatusCard(status: state.safetyStatus),

                  const SizedBox(height: 20),

                  // Smart Shoe Status Card
                  ShoeStatusCard(shoeStatus: state.shoeStatus),

                  const SizedBox(height: 28),

                  // Central SOS Hold Button (Creates Real Firestore Emergency)
                  Center(
                    child: SOSButton(
                      onTrigger: () => _onSosTriggered(context, ref),
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

                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.peopleIProtect.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final contact = state.peopleIProtect[index];
                        return PersonCard(contact: contact);
                      },
                    ),
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
