import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/aeemg_hero.dart';
import '../../../../shared/widgets/ds/aeemg_motion.dart';
import '../../data/donations_repository.dart';

/// Bandeau « don rapide » : montants en pilules. Sans `onAmount`, invite à se connecter.
class QuickDonateCard extends StatelessWidget {
  const QuickDonateCard({
    super.key,
    required this.currency,
    required this.onAmount,
    required this.onLogin,
  });

  static const amounts = [5000, 10000, 25000];

  final NumberFormat currency;
  final ValueChanged<int>? onAmount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AeemgHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'SADAQA',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Faire un don rapide', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Chaque contribution soutient les actions de l'AEEMG.",
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (onAmount == null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Connectez-vous pour donner.',
                    style: AppTypography.caption,
                  ),
                ),
                TextButton(
                  onPressed: onLogin,
                  child: const Text('Se connecter'),
                ),
              ],
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final amount in amounts)
                  _AmountChip(
                    label: currency.format(amount),
                    onTap: () => onAmount!(amount),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AeemgPressable(
      child: Material(
        color: AppColors.deepNavy.withValues(alpha: 0.35),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.smMd,
            ),
            child: Text(
              label,
              style: AppTypography.h4.copyWith(color: AppColors.goldLight),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte d'une campagne : progression en dégradé, montants, bouton de contribution.
class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    required this.currency,
    required this.onContribute,
  });

  final DonationCampaign campaign;
  final NumberFormat currency;

  /// `null` : utilisateur non connecté.
  final VoidCallback? onContribute;

  @override
  Widget build(BuildContext context) {
    final progress = campaign.progress.clamp(0.0, 1.0);
    final percent = '${(progress * 100).toStringAsFixed(0)} %';
    return AeemgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(campaign.title, style: AppTypography.h3)),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(label: percent, tint: AppColors.brightGreen),
            ],
          ),
          if (campaign.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              campaign.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Progression de la collecte',
            value: percent,
            child: _ProgressBar(progress: progress),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currency.format(campaign.raisedAmount)} collectés',
                style: AppTypography.caption.copyWith(
                  color: AppColors.brightGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Objectif ${currency.format(campaign.goalAmount)}',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (onContribute != null)
            AeemgPrimaryButton(
              label: 'Contribuer (10 000 GNF)',
              icon: Icons.favorite_rounded,
              onPressed: onContribute,
            )
          else
            Center(
              child: Text(
                'Connectez-vous pour contribuer.',
                style: AppTypography.caption,
              ),
            ),
        ],
      ),
    );
  }
}

/// Barre de progression en dégradé, qui se remplit à l'apparition (sauf animations réduites).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillBorder,
      child: Container(
        height: 8,
        color: AppColors.cardSurfaceLight,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.slow,
          curve: AppMotion.standard,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
