import 'package:flutter/material.dart';
import 'package:stock_app/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool withPattern;

  const GradientBackground({
    super.key,
    required this.child,
    this.withPattern = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Stack(
        children: [
          if (withPattern)
            Positioned.fill(
              child: CustomPaint(painter: BackgroundPatternPainter()),
            ),
          child,
        ],
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = -size.height; i < size.height * 2; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
