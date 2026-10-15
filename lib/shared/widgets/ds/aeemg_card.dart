import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'aeemg_motion.dart';

/// `accentMint` est conservé pour compatibilité : il s'affiche comme `accent`.
enum AeemgCardVariant { primary, accent, accentMint, active }

class AeemgCard extends StatelessWidget {
  const AeemgCard({
    super.key,
    required this.child,
    this.variant = AeemgCardVariant.primary,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final AeemgCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  BoxDecoration get _decoration => BoxDecoration(
    color: switch (variant) {
      AeemgCardVariant.accent ||
      AeemgCardVariant.accentMint => AppColors.darkTeal.withValues(alpha: 0.55),
      _ => null,
    },
    // Reflet en haut des cartes standard (v3) : du relief sans ombre.
    gradient: switch (variant) {
      AeemgCardVariant.primary ||
      AeemgCardVariant.active => AppGradients.surface,
      _ => null,
    },
    borderRadius: AppRadius.cardBorder,
    border: Border.all(
      color: switch (variant) {
        AeemgCardVariant.active => AppColors.emerald,
        AeemgCardVariant.accent || AeemgCardVariant.accentMint =>
          AppColors.emerald.withValues(alpha: 0.35),
        AeemgCardVariant.primary => AppColors.border,
      },
      width: variant == AeemgCardVariant.active ? 1.5 : 1,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    final card = DecoratedBox(
      decoration: _decoration,
      child: onTap == null
          ? content
          : Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.cardBorder,
                child: content,
              ),
            ),
    );
    return onTap == null ? card : AeemgPressable(child: card);
  }
}

/// Carte pour versets, hadiths et rappels : filet doré à gauche, texte en italique.
class AeemgAccentCard extends StatelessWidget {
  const AeemgAccentCard({
    super.key,
    required this.title,
    required this.body,
    this.source,
    this.icon = Icons.menu_book_outlined,
    this.onTap,
  });

  final String title;
  final String body;
  final String? source;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppColors.gold, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            style: AppTypography.overline.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    Text(
                      body.trimLeft().startsWith('«') ? body : '« $body »',
                      style: AppTypography.bodyLarge.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (source != null && source!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(source!, style: AppTypography.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
