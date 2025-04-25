import 'dart:math';
import 'package:flutter/material.dart';

class StarryNightBackground extends StatefulWidget {
  final int starCount;
  final List<Color> starColors;
  final List<double> starSizes;
  final Gradient? backgroundGradient;

  const StarryNightBackground({
    this.starCount = 180,
    this.starColors = const [
      Colors.white,
      Color(0xFFB0C4DE),
      Color(0xFF87CEEB),
    ],
    this.starSizes = const [0.8, 1.0, 1.4, 2.0],
    this.backgroundGradient,
    super.key,
  });

  @override
  State<StarryNightBackground> createState() => _StarryNightBackgroundState();
}

class _StarryNightBackgroundState extends State<StarryNightBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_StarData> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _stars = _generateStars();
  }

  List<_StarData> _generateStars() {
    final rand = Random(2025);
    final stars = <_StarData>[];
    for (int i = 0; i < widget.starCount; i++) {
      stars.add(
        _StarData(
          dx: rand.nextDouble(),
          dy: rand.nextDouble(),
          color: widget.starColors[rand.nextInt(widget.starColors.length)],
          baseRadius:
              widget.starSizes[rand.nextInt(widget.starSizes.length)] +
              rand.nextDouble() * 0.8,
          twinklePhase: rand.nextDouble() * 2 * pi,
          twinkleSpeed:
              0.7 +
              rand.nextDouble() *
                  0.8, // Each star twinkles at a slightly different speed
        ),
      );
    }
    return stars;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AnimatedStarryNightPainter(
            stars: _stars,
            animationValue: _controller.value,
            backgroundGradient:
                widget.backgroundGradient ??
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D1026),
                    Color(0xFF181C36),
                    Color(0xFF22264C),
                  ],
                ),
          ),
          child: Container(),
        );
      },
    );
  }
}

class _StarData {
  final double dx;
  final double dy;
  final Color color;
  final double baseRadius;
  final double twinklePhase;
  final double twinkleSpeed;

  _StarData({
    required this.dx,
    required this.dy,
    required this.color,
    required this.baseRadius,
    required this.twinklePhase,
    required this.twinkleSpeed,
  });
}

class _AnimatedStarryNightPainter extends CustomPainter {
  final List<_StarData> stars;
  final double animationValue;
  final Gradient backgroundGradient;

  _AnimatedStarryNightPainter({
    required this.stars,
    required this.animationValue,
    required this.backgroundGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint gradient background
    final rect = Offset.zero & size;
    final paint = Paint()..shader = backgroundGradient.createShader(rect);
    canvas.drawRect(rect, paint);

    for (final star in stars) {
      final dx = star.dx * size.width;
      final dy = star.dy * size.height;
      // Twinkle: brightness varies smoothly over time, each star has its own phase/speed
      final twinkle =
          0.7 +
          0.3 *
              (0.5 +
                  0.5 *
                      sin(
                        star.twinklePhase +
                            animationValue * 2 * pi * star.twinkleSpeed,
                      ));
      final color = star.color.withAlpha((star.color.alpha * twinkle).toInt());
      final starPaint =
          Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
      canvas.drawCircle(Offset(dx, dy), star.baseRadius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedStarryNightPainter oldDelegate) => true;
}
