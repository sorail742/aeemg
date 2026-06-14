import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class IslamicBackground extends StatelessWidget {
  const IslamicBackground({
    super.key,
    required this.child,
    this.withPattern = false,
  });

  final Widget child;
  final bool withPattern;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepNavy,
            AppColors.darkCharcoal,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Optional pattern overlay (using a simple custom painter for now
          // to simulate a geometric pattern without needing image assets)
          if (withPattern)
            Opacity(
              opacity: 0.03, // Very subtle
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
              ),
            ),
          // Glow effect top right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.15),
                // We use a high blur to create a soft glow
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double step = 60;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        // Draw simple octagons
        final path = Path();
        final s = step / 3;
        path.moveTo(x + s, y);
        path.lineTo(x + 2 * s, y);
        path.lineTo(x + step, y + s);
        path.lineTo(x + step, y + 2 * s);
        path.lineTo(x + 2 * s, y + step);
        path.lineTo(x + s, y + step);
        path.lineTo(x, y + 2 * s);
        path.lineTo(x, y + s);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
