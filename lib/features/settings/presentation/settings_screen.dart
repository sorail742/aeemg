import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_page.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/aeemg_settings.dart';
import '../../notifications/presentation/notification_settings_screen.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeCodeProvider);
    final user = ref.watch(currentUserProvider);

    return AeemgPage(
      title: AppStrings.t('settings', locale),
      subtitle: 'Langue, contenu hors ligne et alertes.',
      children: [
        AeemgSectionHeader(title: AppStrings.t('language', locale)),
        AeemgSegmented<String>(
          options: const [('fr', 'Français'), ('ff', 'Peul')],
          selected: locale,
          onChanged: (code) => setAppLocale(ref, code),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AeemgSectionHeader(title: 'Général'),
        // Le cache hors ligne est toujours actif : un badge, pas un faux interrupteur.
        AeemgSettingsTile(
          icon: Icons.offline_bolt_outlined,
          tint: AppColors.gold,
          title: AppStrings.t('offline_mode', locale),
          subtitle: AppStrings.t('offline_hint', locale),
          trailing: const _StatusBadge(label: 'Actif'),
        ),
        if (user != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const AeemgSectionHeader(title: 'Notifications'),
          AeemgSettingsTile(
            icon: Icons.tune_rounded,
            title: 'Préférences d\'alertes',
            subtitle: 'Événements, finances, messages, rappels',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push('/notifications/settings'),
          ),
          ref
              .watch(notificationPreferencesProvider)
              .when(
                loading: () => const AeemgSkeletonTile(),
                error: (_, _) => const SizedBox.shrink(),
                data: (prefs) => AeemgSwitchTile(
                  icon: Icons.sms_outlined,
                  title: 'SMS de secours',
                  subtitle:
                      'Recevoir un SMS si les notifications in-app échouent',
                  value: prefs.smsFallbackEnabled,
                  onChanged: (v) async {
                    final updated = prefs.copyWith(smsFallbackEnabled: v);
                    await ref
                        .read(notificationPreferencesRepositoryProvider)
                        .upsert(user.id, updated);
                    ref.invalidate(notificationPreferencesProvider);
                  },
                ),
              ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.brightGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
