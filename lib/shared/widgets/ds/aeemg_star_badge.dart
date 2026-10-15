import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Numéro dans une étoile à huit branches (khatam) : sourates, juz, hadiths.
class AeemgStarBadge extends StatelessWidget {
  const AeemgStarBadge({
    super.key,
    required this.label,
    this.size = 44,
    this.tint = AppColors.brightGreen,
  });

  final String label;
  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(tint),
        child: Center(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
              fontSize: label.length > 2 ? 11 : 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.tint);

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final half = size.shortestSide * 0.36;
    final star = Path();
    for (final angle in const [0.0, math.pi / 4]) {
      star.addPolygon([
        for (var k = 0; k < 4; k++)
          center +
              Offset(
                math.cos(angle + k * math.pi / 2) * half * math.sqrt2,
                math.sin(angle + k * math.pi / 2) * half * math.sqrt2,
              ),
      ], true);
    }
    canvas
      ..drawPath(star, Paint()..color = tint.withValues(alpha: 0.12))
      ..drawPath(
        star,
        Paint()
          ..color = tint.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.tint != tint;
}
