import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/mock_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: "Protection that doesn't depend on your phone.",
      icon: Icons.directions_run_rounded,
      features: [
        _FeatureItem(Icons.accessibility_new_rounded, 'Fall detection'),
        _FeatureItem(Icons.touch_app_rounded, 'Manual stomp trigger'),
        _FeatureItem(Icons.cell_tower_rounded, 'Independent emergency communication'),
      ],
    ),
    _OnboardingData(
      title: "Triple Redundancy Emergency System.",
      icon: Icons.alt_route_rounded,
      features: [
        _FeatureItem(Icons.bluetooth_audio_rounded, 'BLE Direct Mesh Network'),
        _FeatureItem(Icons.wifi_tethering_rounded, 'Cellular 4G Data Sync'),
        _FeatureItem(Icons.sms_rounded, 'Fail-safe SMS Dispatch'),
      ],
    ),
    _OnboardingData(
      title: "Protection that multiplies through trusted people.",
      icon: Icons.group_work_rounded,
      features: [
        _FeatureItem(Icons.shield_moon_rounded, 'Two-way Guardian Network'),
        _FeatureItem(Icons.my_location_rounded, 'Live GPS Tracking'),
        _FeatureItem(Icons.local_police_rounded, 'Instant Emergency 112 Dispatch'),
      ],
    ),
  ];

  void _finishOnboarding() {
    ref.read(mockStateProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Skip)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration card
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.surfaceContainerHighest,
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  AppColors.primaryContainer.withOpacity(0.2),
                              child: Icon(
                                data.icon,
                                size: 56,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // Bento features list
                        Column(
                          children: data.features.map((feat) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surfaceContainerHighest,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryContainer
                                        .withOpacity(0.2),
                                    child: Icon(
                                      feat.icon,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      feat.label,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Nav / Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == idx ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx
                              ? AppColors.primary
                              : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final IconData icon;
  final List<_FeatureItem> features;

  const _OnboardingData({
    required this.title,
    required this.icon,
    required this.features,
  });
}

class _FeatureItem {
  final IconData icon;
  final String label;

  const _FeatureItem(this.icon, this.label);
}
