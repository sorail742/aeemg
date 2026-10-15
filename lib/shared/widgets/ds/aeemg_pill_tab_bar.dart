import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Onglets en pilule (v3) : l'onglet actif porte le dégradé du bouton principal.
/// Sans `controller`, utilise le `DefaultTabController` le plus proche.
class AeemgPillTabBar extends StatelessWidget {
  const AeemgPillTabBar({super.key, required this.labels, this.controller});

  final List<String> labels;
  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: AppRadius.pillBorder,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.transparent,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: [for (final label in labels) Tab(text: label)],
      ),
    );
  }
}
