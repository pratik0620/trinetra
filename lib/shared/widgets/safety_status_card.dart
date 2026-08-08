import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';

class SafetyStatusCard extends StatefulWidget {
  final SafetyStatusEnum status;

  const SafetyStatusCard({
    super.key,
    required this.status,
  });

  @override
  State<SafetyStatusCard> createState() => _SafetyStatusCardState();
}

class _SafetyStatusCardState extends State<SafetyStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusTitle;
    String statusSubtitle;

    switch (widget.status) {
      case SafetyStatusEnum.safe:
        statusColor = AppColors.tertiary;
        statusTitle = 'YOU ARE SAFE';
        statusSubtitle = 'RAKSHA is monitoring your safety';
        break;
      case SafetyStatusEnum.warning:
        statusColor = AppColors.warning;
        statusTitle = 'WARNING / VERIFYING';
        statusSubtitle = 'Suspicious movement detected';
        break;
      case SafetyStatusEnum.emergency:
        statusColor = AppColors.secondaryContainer;
        statusTitle = 'EMERGENCY ACTIVE';
        statusSubtitle = 'SOS Signal transmitting';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  FadeTransition(
                    opacity: _pulseAnimation,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  statusSubtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
