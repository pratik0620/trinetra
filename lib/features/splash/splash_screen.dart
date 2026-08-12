import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/mock_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _checkSessionAndNavigate();
  }

  void _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    bool navigated = false;

    try {
      // 1. Initialize and request location permissions on app startup
      final locationService = ref.read(liveLocationServiceProvider);
      final permGranted = await locationService.checkAndRequestPermission();
      debugPrint('[SPLASH] Location permission status on app launch: granted=$permGranted');

      final authService = ref.read(authServiceProvider);
      final userRepo = ref.read(userRepositoryProvider);


      final savedPhone = await authService
          .getLocalSessionPhone()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      final savedUid = await authService
          .getLocalSessionUid()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (savedPhone != null && savedPhone.isNotEmpty && savedUid != null) {
        final userProfile = await userRepo
            .getUserProfile(savedUid)
            .timeout(const Duration(seconds: 2), onTimeout: () => null);

        if (userProfile != null) {
          ref.read(activeUserUidProvider.notifier).state = savedUid;
          ref.read(mockStateProvider.notifier).login();

          // Initialize FCM NotificationService in background (non-blocking)
          unawaited(
            ref.read(notificationServiceProvider).initialize(
              savedUid,
              onEmergencyTap: (emergencyId) {
                AppRouter.router.go('/guardian-sos-active?emergencyId=$emergencyId');
              },
            ).catchError((e) {
              debugPrint('FCM init note: $e');
            }),
          );

          if (mounted) {
            navigated = true;
            context.go('/home');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Session check note: $e');
    }

    if (!mounted || navigated) return;
    try {
      final state = ref.read(mockStateProvider);
      if (state.hasCompletedOnboarding) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Navigation fallback note: $e');
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // RAKSHA Splash Logo — final approved asset
                    Image.asset(
                      'assets/images/raksha_logo.png',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                    ),

                  ],
                ),
              ),
            ),
          ),

          // Bottom Loading Line
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 60,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
