import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MapPlaceholderWidget extends StatelessWidget {
  final bool isEmergencyMode;
  final String focusName;
  final String distanceText;

  const MapPlaceholderWidget({
    super.key,
    this.isEmergencyMode = false,
    this.focusName = 'Priya',
    this.distanceText = '2.4 km',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A24),
      child: Stack(
        children: [
          // Grid background simulation
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(isEmergencyMode: isEmergencyMode),
          ),

          // User Pin
          Positioned(
            bottom: 120,
            left: 100,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryContainer,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(fontSize: 10, color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),

          // Target / SOS Pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isEmergencyMode
                                ? AppColors.secondaryContainer
                                : AppColors.tertiary)
                            .withOpacity(0.3),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEmergencyMode
                            ? AppColors.secondaryContainer
                            : AppColors.tertiary,
                        boxShadow: [
                          BoxShadow(
                            color: isEmergencyMode
                                ? AppColors.secondaryContainer
                                : AppColors.tertiary,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        isEmergencyMode
                            ? Icons.person_pin_circle_rounded
                            : Icons.shield_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEmergencyMode
                          ? AppColors.secondaryContainer
                          : AppColors.tertiary,
                    ),
                  ),
                  child: Text(
                    isEmergencyMode ? '$focusName - SOS' : focusName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEmergencyMode
                          ? AppColors.secondaryContainer
                          : AppColors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Info Pill (Distance & Live Status)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEmergencyMode
                              ? AppColors.secondaryContainer
                              : AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEmergencyMode
                            ? 'Live Tracking'
                            : 'Protected Connections',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEmergencyMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'DISTANCE',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final bool isEmergencyMode;

  _MapGridPainter({required this.isEmergencyMode});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Road paths
    final roadPaint = Paint()
      ..color = (isEmergencyMode
              ? AppColors.secondaryContainer
              : AppColors.primaryContainer)
          .withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.3,
        size.width * 0.6,
        size.height * 0.6,
        size.width,
        size.height * 0.5,
      );

    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
