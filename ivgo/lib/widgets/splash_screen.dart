import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _heartbeatController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  double _iconFadeProgress(double value) => (value * 2.5).clamp(0, 1);

  double _textOpacity(double value) => ((value - 0.2) * 2.5).clamp(0, 1);

  double _textOffset(double value) {
    final p = ((value - 0.2) * 2.5).clamp(0, 1);
    return 16.0 * (1 - p);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1565C0) : const Color(0xFFB3E5FC);
    final fgColor = Colors.white;
    final accentColor = isDark ? Colors.white70 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _heartbeatController]),
          builder: (context, _) {
            final value = _controller.value;
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: _iconFadeProgress(value),
                          child: Icon(Icons.vaccines, size: 120, color: fgColor),
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 220,
                    height: 60,
                    child: CustomPaint(
                      painter: _HeartbeatPainter(
                        progress: _heartbeatController.value,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
