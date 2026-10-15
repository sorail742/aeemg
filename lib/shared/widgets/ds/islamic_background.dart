import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Fond des écrans : dégradé sombre, halo émeraude en haut et, en option, un motif
/// d'étoiles à huit branches (khatam) à peine perceptible. Tout est peint une seule fois
/// (RepaintBoundary) : aucun coût pendant le défilement.
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.glow),
            ),
          ),
          if (withPattern)
            const IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: IslamicPatternPainter()),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Motif d'étoiles à huit branches (deux carrés superposés, l'un tourné de 45°).
class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter({this.opacity = 0.022, this.step = 64});

  final double opacity;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final half = step * 0.22;
    final star = Path();
    for (final angle in const [0.0, math.pi / 4]) {
      final points = [
        for (var k = 0; k < 4; k++)
          Offset(
            math.cos(angle + k * math.pi / 2) * half * math.sqrt2,
            math.sin(angle + k * math.pi / 2) * half * math.sqrt2,
          ),
      ];
      star.addPolygon(points, true);
    }

    for (double y = step / 2; y < size.height + step; y += step) {
      for (double x = step / 2; x < size.width + step; x += step) {
        canvas.drawPath(star.shift(Offset(x, y)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.step != step;
}
