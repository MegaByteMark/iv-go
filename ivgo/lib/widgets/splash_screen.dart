import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _crosshairProgress(double value) => (value * 2.5).clamp(0, 1);

  double _heartbeatProgress(double value) => ((value - 0.15) * 1.8).clamp(0, 1);

  double _textOpacity(double value) => ((value - 0.6) * 3).clamp(0, 1);

  double _textOffset(double value) {
    final p = ((value - 0.6) * 3).clamp(0, 1);
    return 20.0 * (1 - p);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D2137) : const Color(0xFFB3E5FC);
    final fgColor = isDark ? Colors.white70 : Colors.white;
    final accentColor = isDark ? Colors.lightBlue.shade200 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = _controller.value;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _CrosshairPainter(
                        progress: _crosshairProgress(value),
                        color: fgColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 220,
                    height: 60,
                    child: CustomPaint(
                      painter: _HeartbeatPainter(
                        progress: _heartbeatProgress(value),
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Opacity(
                          opacity: _textOpacity(value),
                          child: Transform.translate(
                            offset: Offset(0, _textOffset(value)),
                            child: Text(
                              'IV Go',
                              style: TextStyle(
                                color: fgColor,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: _textOpacity(value),
                          child: Transform.translate(
                            offset: Offset(0, _textOffset(value)),
                            child: Text(
                              'Infusion Timer',
                              style: TextStyle(
                                color: fgColor.withValues(alpha: 0.7),
                                fontSize: 14,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        fgColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: progress)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final armLength = size.width * 0.35 * progress;
    final gap = size.width * 0.08;

    final paint2 = Paint()
      ..color = color.withValues(alpha: (progress * 0.3).clamp(0, 1))
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final pulseRadius = size.width * 0.45 * (1 + 0.08 * math.sin(progress * math.pi * 6));

    canvas.drawCircle(center, pulseRadius, paint2);

    canvas.drawLine(
      Offset(center.dx - armLength, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + armLength, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - armLength),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + armLength),
      paint,
    );

    final circlePaint = Paint()
      ..color = color.withValues(alpha: progress * 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size.width * 0.12, circlePaint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) => oldDelegate.progress != progress;
}

class _HeartbeatPainter extends CustomPainter {
  _HeartbeatPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final amp = h * 0.35;

    final path = Path();
    path.moveTo(0, midY);

    path.lineTo(w * 0.18, midY);

    path.cubicTo(
      w * 0.22, midY - amp * 0.25,
      w * 0.26, midY + amp * 0.15,
      w * 0.30, midY,
    );

    path.lineTo(w * 0.38, midY);

    path.lineTo(w * 0.40, midY + amp * 0.7);

    path.lineTo(w * 0.44, midY - amp * 1.2);

    path.lineTo(w * 0.47, midY + amp * 0.5);

    path.lineTo(w * 0.52, midY);

    path.lineTo(w * 0.62, midY);

    path.cubicTo(
      w * 0.67, midY - amp * 0.3,
      w * 0.76, midY - amp * 0.2,
      w * 0.82, midY,
    );

    path.lineTo(w, midY);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractLength = metric.length * progress;
      final extractPath = metric.extractPath(0, extractLength);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(_HeartbeatPainter oldDelegate) => oldDelegate.progress != progress;
}
