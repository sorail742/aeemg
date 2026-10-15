import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/aeemg_motion.dart';

/// En-tête compact : marque et accès rapides aux messages et notifications.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: AppShadows.glow,
          ),
          child: const Icon(
            Icons.mosque_rounded,
            color: AppColors.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.smMd),
        Text('AEEMG', style: AppTypography.h3.copyWith(letterSpacing: 1.5)),
        const Spacer(),
        AeemgRoundIconButton(
          tooltip: 'Messages',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () => context.push('/messages'),
        ),
        const SizedBox(width: AppSpacing.sm),
        AeemgRoundIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          badge: unreadCount,
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

/// Pastille du bandeau (date hégirienne).
class HomeHeroChip extends StatelessWidget {
  const HomeHeroChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.scrim.withValues(alpha: 0.25),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.goldLight),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Raccourci de l'accueil : pastille d'icône teintée (une couleur par usage) et libellé.
class HomeQuickAccess extends StatelessWidget {
  const HomeQuickAccess({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: AeemgPressable(
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint.withValues(alpha: 0.28),
                          tint.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tint.withValues(alpha: 0.35)),
                    ),
                    child: Icon(icon, color: tint, size: 26),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne de liste en carte : pastille d'icône, titre, sous-titre sur deux lignes.
class HomeListCard extends StatelessWidget {
  const HomeListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tint = highlight ? AppColors.gold : AppColors.brightGreen;
    return AeemgCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
