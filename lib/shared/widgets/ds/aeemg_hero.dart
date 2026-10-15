import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'islamic_background.dart';

/// Bandeau d'en-tête (v3) : dégradé émeraude profond, motif étoilé plus visible que sur
/// le fond et halo doré discret. Réservé au premier élément d'un écran de section.
class AeemgHero extends StatelessWidget {
  const AeemgHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.mdLg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.hero);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: radius,
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.28)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: IslamicPatternPainter(opacity: 0.06, step: 44),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -60,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.18),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
