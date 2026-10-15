import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import 'ds/aeemg_nav_bar.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeCodeProvider);

    return Scaffold(
      // Même teinte que le bas du fond des écrans : la barre flottante semble posée
      // sur le contenu sans le masquer.
      backgroundColor: AppColors.darkCharcoal,
      body: navigationShell,
      bottomNavigationBar: AeemgNavBar(
        currentIndex: navigationShell.currentIndex,
        // Un second appui sur l'onglet actif revient à sa racine.
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          AeemgNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: AppStrings.t('nav_home', locale),
          ),
          AeemgNavItem(
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
            label: AppStrings.t('nav_social', locale),
          ),
          AeemgNavItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month_rounded,
            label: AppStrings.t('nav_agenda', locale),
          ),
          AeemgNavItem(
            icon: Icons.mosque_outlined,
            selectedIcon: Icons.mosque_rounded,
            label: AppStrings.t('nav_mosque', locale),
          ),
          AeemgNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: AppStrings.t('nav_profile', locale),
          ),
        ],
      ),
    );
  }
}
