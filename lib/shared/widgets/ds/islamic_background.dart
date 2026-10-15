import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Fond des écrans : dégradé sombre et, en option, un motif géométrique à peine
/// perceptible (identité islamique sans charger l'interface).
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deepNavy, AppColors.darkCharcoal],
        ),
      ),
      child: withPattern
          ? Stack(
              fit: StackFit.expand,
              children: [
                const IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _IslamicPatternPainter()),
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  const _IslamicPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 72.0;
    const s = step / 3;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final path = Path()
          ..moveTo(x + s, y)
          ..lineTo(x + 2 * s, y)
          ..lineTo(x + step, y + s)
          ..lineTo(x + step, y + 2 * s)
          ..lineTo(x + 2 * s, y + step)
          ..lineTo(x + s, y + step)
          ..lineTo(x, y + 2 * s)
          ..lineTo(x, y + s)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
