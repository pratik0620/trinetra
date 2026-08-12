import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/name_setup_screen.dart';
import '../../features/emergency/guardian_emergency_active_screen.dart';
import '../../features/emergency/guardian_emergency_responding_screen.dart';
import '../../features/emergency/guardian_emergency_resolved_screen.dart';
import '../../features/emergency/my_emergency_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/people/people_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shoe/shoe_status_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';
import '../../shared/widgets/demo_controls_widget.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/name-setup',
        builder: (context, state) => NameSetupScreen(
          phone: state.uri.queryParameters['phone'],
        ),
      ),

      // Shell Route for Main Bottom Navigation Tabs
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          int currentIndex = 0;
          final location = state.uri.toString();

          if (location.startsWith('/map')) {
            currentIndex = 1;
          } else if (location.startsWith('/people')) {
            currentIndex = 2;
          } else if (location.startsWith('/profile')) {
            currentIndex = 3;
          }

          return Scaffold(
            body: Stack(
              children: [
                child,
                const DemoControlsFloatingWidget(),
              ],
            ),
            bottomNavigationBar: AppBottomNavBar(currentIndex: currentIndex),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/people',
            builder: (context, state) => const PeopleScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Secondary Screens & Full-screen Overlays (No Bottom Bar)
      GoRoute(
        path: '/shoe-status',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShoeStatusScreen(),
      ),
      GoRoute(
        path: '/my-sos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MyEmergencyScreen(
          emergencyId: state.uri.queryParameters['emergencyId'],
        ),
      ),
      GoRoute(
        path: '/guardian-sos-active',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GuardianEmergencyActiveScreen(
          emergencyId: state.uri.queryParameters['emergencyId'],
        ),
      ),
      GoRoute(
        path: '/guardian-responding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GuardianEmergencyRespondingScreen(
          emergencyId: state.uri.queryParameters['emergencyId'],
        ),
      ),
      GoRoute(
        path: '/guardian-resolved',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GuardianEmergencyResolvedScreen(),
      ),
    ],
  );
}
