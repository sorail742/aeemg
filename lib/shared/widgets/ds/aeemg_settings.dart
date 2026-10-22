import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'aeemg_card.dart';

/// Ligne de réglage (v3) : pastille d'icône teintée, titre, explication et
/// élément à droite (badge, chevron…). Toute la carte réagit si `onTap` est donné.
class AeemgSettingsTile extends StatelessWidget {
  const AeemgSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tint = AppColors.emerald,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AeemgCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Réglage tout ou rien : un appui n'importe où sur la carte bascule la valeur,
/// et le lecteur d'écran l'annonce comme un seul interrupteur.
class AeemgSwitchTile extends StatelessWidget {
  const AeemgSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.tint = AppColors.emerald,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;

  /// `null` : réglage désactivé (enregistrement en cours, par exemple).
  final ValueChanged<bool>? onChanged;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: AeemgSettingsTile(
        icon: icon,
        tint: tint,
        title: title,
        subtitle: subtitle,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

/// Choix exclusif en pilules (langue…) : le segment actif porte le dégradé
/// principal, comme `AeemgPillTabBar`, sans `TabController`.
class AeemgSegmented<T> extends StatelessWidget {
  const AeemgSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.base;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                selected: value == selected,
                button: true,
                child: Material(
                  color: AppColors.transparent,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: value == selected ? null : () => onChanged(value),
                    child: AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.standard,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: value == selected
                            ? AppGradients.primary
                            : null,
                        borderRadius: AppRadius.pillBorder,
                      ),
                      child: Text(
                        label,
                        style: AppTypography.caption.copyWith(
                          fontWeight: value == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: value == selected
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
