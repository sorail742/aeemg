import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Retour tactile : l'élément s'enfonce légèrement sous le doigt. Écoute les pointeurs
/// sans participer à l'arène des gestes : le `onTap` de l'enfant (InkWell, bouton)
/// fonctionne normalement.
class AeemgPressable extends StatefulWidget {
  const AeemgPressable({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<AeemgPressable> createState() => _AeemgPressableState();
}

class _AeemgPressableState extends State<AeemgPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}

/// Apparition d'un élément (fondu + léger glissement vers le haut), décalée selon sa
/// position dans la liste. Sans effet si les animations sont réduites.
extension AeemgReveal on Widget {
  Widget reveal(BuildContext context, {int index = 0}) {
    if (AppMotion.reduced(context)) return this;
    final position = index.clamp(0, AppMotion.maxStaggered);
    return animate(delay: AppMotion.stagger * position)
        .fadeIn(duration: AppMotion.slow, curve: AppMotion.standard)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        );
  }
}

/// Bloc de chargement : forme grise traversée d'un reflet, à la place d'un indicateur
/// circulaire (le contenu à venir est annoncé, la page ne « saute » pas).
class AeemgSkeleton extends StatelessWidget {
  const AeemgSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.small,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (AppMotion.reduced(context)) return block;
    return block
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: AppColors.white.withValues(alpha: 0.06),
        );
  }
}

/// Carte de chargement : pastille et deux lignes, à la forme d'une ligne de liste.
class AeemgSkeletonTile extends StatelessWidget {
  const AeemgSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            AeemgSkeleton(width: 40, height: 40, radius: AppRadius.medium),
            SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AeemgSkeleton(width: 160),
                  SizedBox(height: AppSpacing.sm),
                  AeemgSkeleton(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
