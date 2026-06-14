import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

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
          AeemgCardVariant.primary => AppColors.cardSurface,
          AeemgCardVariant.accent => AppColors.darkTeal,
          AeemgCardVariant.accentMint => AppColors.softMint,
          AeemgCardVariant.active => AppColors.cardSurface,
        },
        borderRadius: AppRadius.cardBorder,
        border: variant == AeemgCardVariant.active
            ? Border.all(color: AppColors.emerald, width: 2)
            : variant == AeemgCardVariant.accent
                ? Border.all(color: AppColors.emerald.withValues(alpha: 0.4))
                : null,
        boxShadow: AppShadows.card,
      );

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );

    if (onTap != null) {
      return DecoratedBox(
        decoration: _decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardBorder,
            child: content,
          ),
        ),
      );
    }

    return DecoratedBox(decoration: _decoration, child: content);
  }
}

/// Carte pour versets / citations islamiques.
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
      variant: AeemgCardVariant.accentMint,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.darkTeal, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.darkTeal,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Text(
            '« $body »',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkCharcoal,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
          ),
          if (source != null && source!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              source!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkTeal,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
