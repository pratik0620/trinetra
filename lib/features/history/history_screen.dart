import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/mock_state_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mockStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety History',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Review your recent activity and safety events.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // Vertical Timeline
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.historyEvents.length,
                itemBuilder: (context, index) {
                  final event = state.historyEvents[index];
                  final isLast = index == state.historyEvents.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left timeline line & indicator
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getEventColor(event.type),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getEventColor(event.type),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.surfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Event Card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: event.type == EventType.critical
                                      ? AppColors.emergency.withOpacity(0.5)
                                      : AppColors.surfaceVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getEventIcon(event.type),
                                            size: 18,
                                            color: _getEventColor(event.type),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            event.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: event.type ==
                                                      EventType.critical
                                                  ? AppColors.emergency
                                                  : AppColors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        event.timestamp,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        event.subtitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getBadgeBgColor(event.type),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          event.badgeText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _getBadgeTextColor(event.type),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.normal:
        return AppColors.tertiary;
      case EventType.warning:
        return AppColors.warning;
      case EventType.critical:
        return AppColors.emergency;
      case EventType.resolved:
        return AppColors.tertiary;
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.normal:
        return Icons.check_circle_rounded;
      case EventType.warning:
        return Icons.warning_rounded;
      case EventType.critical:
        return Icons.emergency_rounded;
      case EventType.resolved:
        return Icons.verified_rounded;
    }
  }

  Color _getBadgeBgColor(EventType type) {
    switch (type) {
      case EventType.normal:
        return AppColors.tertiaryContainer;
      case EventType.warning:
        return AppColors.warningContainer;
      case EventType.critical:
        return AppColors.errorContainer;
      case EventType.resolved:
        return AppColors.tertiaryContainer;
    }
  }

  Color _getBadgeTextColor(EventType type) {
    switch (type) {
      case EventType.normal:
        return AppColors.onTertiaryContainer;
      case EventType.warning:
        return AppColors.onWarningContainer;
      case EventType.critical:
        return AppColors.onErrorContainer;
      case EventType.resolved:
        return AppColors.onTertiaryContainer;
    }
  }
}
