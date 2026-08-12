import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/nearby_relay_provider.dart';

class RAKSHAApp extends ConsumerWidget {
  const RAKSHAApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly instantiate the nearbyRelayStateProvider to start adaptive background scanning/advertising.
    ref.watch(nearbyRelayStateProvider);

    return MaterialApp.router(
      title: 'RAKSHA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
