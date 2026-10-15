import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'aeemg_motion.dart';
import 'islamic_background.dart';

/// Page secondaire v3 : bouton rond Retour, grand titre, sous-titre facultatif, actions
/// rondes, puis le contenu en apparition décalée. Remplace l'AppBar transparente et la
/// marge haute calculée à la main dans chaque écran.
class AeemgPage extends StatelessWidget {
  const AeemgPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;

  /// Boutons d'en-tête, en général des [AeemgRoundIconButton].
  final List<Widget> actions;
  final List<Widget> children;

  /// Active le rafraîchissement par glissement.
  final Future<void> Function()? onRefresh;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.paddingOf(context).top,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            if (showBack)
              AeemgRoundIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Retour',
                // Ouvert par un lien direct (web) : retour à l'accueil.
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            const Spacer(),
            for (final action in actions) ...[
              const SizedBox(width: AppSpacing.sm),
              action,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTypography.h1),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: AppTypography.bodySmall),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < children.length; i++)
          children[i].reveal(context, index: i),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: onRefresh == null
            ? list
            : RefreshIndicator(
                color: AppColors.emerald,
                backgroundColor: AppColors.cardSurface,
                onRefresh: onRefresh!,
                child: list,
              ),
      ),
    );
  }
}
