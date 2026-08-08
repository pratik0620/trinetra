import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onTrigger;

  const SOSButton({
    super.key,
    required this.onTrigger,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  Timer? _holdTimer;
  double _progress = 0.0; // 0.0 to 1.0
  bool _isPressed = false;
  bool _isTriggered = false;
  static const int _holdDurationMs = 2000;
  static const int _tickIntervalMs = 20;

  void _startHold() {
    if (_isTriggered) return;

    _holdTimer?.cancel();
    setState(() {
      _isPressed = true;
      _progress = 0.0;
      _isTriggered = false;
    });

    _holdTimer = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _progress += _tickIntervalMs / _holdDurationMs;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _isTriggered = true;
            _holdTimer?.cancel();
            HapticFeedback.vibrate();
            widget.onTrigger();
          }
        });
      },
    );
  }

  void _endHold() {
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPressed = false;
        _progress = 0.0;
        _isTriggered = false;
      });
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Listener(
          onPointerDown: (_) => _startHold(),
          onPointerUp: (_) => _endHold(),
          onPointerCancel: (_) => _endHold(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              CustomPaint(
                size: const Size(180, 180),
                painter: _SOSRingPainter(progress: _progress),
              ),
              // Inner Button
              AnimatedScale(
                scale: _isPressed ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _progress > 0.7
                        ? AppColors.emergency
                        : AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryContainer.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emergency_rounded,
                        size: 48,
                        color: AppColors.onSecondaryContainer,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _progress >= 1.0 ? 'TRIGGERED' : 'HOLD FOR SOS',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SOSRingPainter extends CustomPainter {
  final double progress;

  _SOSRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    final trackPaint = Paint()
      ..color = const Color(0xFF242432)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = AppColors.secondaryContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SOSRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
