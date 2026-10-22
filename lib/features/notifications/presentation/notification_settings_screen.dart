import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_page.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/aeemg_settings.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/notification_preferences_repository.dart';
import 'providers/notifications_provider.dart';

final notificationPreferencesProvider = FutureProvider<NotificationPreferences>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return NotificationPreferences.defaults;
    return ref.read(notificationPreferencesRepositoryProvider).fetch(user.id);
  },
);

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final List<Widget> content;
    if (user == null) {
      content = [
        AeemgEmptyState(
          compact: true,
          icon: Icons.notifications_off_outlined,
          title: 'Préférences personnelles',
          message: 'Connectez-vous pour gérer vos préférences.',
          actionLabel: 'Se connecter',
          onAction: () => context.push('/login'),
        ),
      ];
    } else {
      content = ref
          .watch(notificationPreferencesProvider)
          .when(
            loading: () => const [
              AeemgSkeletonTile(),
              SizedBox(height: AppSpacing.sm),
              AeemgSkeletonTile(),
            ],
            error: (error, _) => [
              AeemgEmptyState(
                compact: true,
                icon: Icons.cloud_off_outlined,
                title: 'Préférences indisponibles',
                message: friendlySupabaseError(error),
              ),
            ],
            data: (prefs) {
              void update(NotificationPreferences updated) =>
                  _save(ref, user.id, updated);
              return [
                const AeemgSectionHeader(title: 'Catégories'),
                AeemgSwitchTile(
                  icon: Icons.event_rounded,
                  tint: AppColors.gold,
                  title: 'Événements',
                  subtitle: 'RSVP, rappels J-7, J-3, J-1',
                  value: prefs.eventsEnabled,
                  onChanged: (v) => update(prefs.copyWith(eventsEnabled: v)),
                ),
                AeemgSwitchTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Finances',
                  subtitle: 'Bilans publiés, campagnes',
                  value: prefs.financeEnabled,
                  onChanged: (v) => update(prefs.copyWith(financeEnabled: v)),
                ),
                AeemgSwitchTile(
                  icon: Icons.forum_rounded,
                  tint: AppColors.info,
                  title: 'Messages',
                  subtitle: 'Annonces et discussions',
                  value: prefs.messagesEnabled,
                  onChanged: (v) => update(prefs.copyWith(messagesEnabled: v)),
                ),
                AeemgSwitchTile(
                  icon: Icons.auto_stories_rounded,
                  tint: AppColors.violet,
                  title: 'Rappels islamiques',
                  subtitle: 'Verset du jour, citations',
                  value: prefs.islamicEnabled,
                  onChanged: (v) => update(prefs.copyWith(islamicEnabled: v)),
                ),
                AeemgSwitchTile(
                  icon: Icons.info_outline_rounded,
                  tint: AppColors.textSecondary,
                  title: 'Général',
                  subtitle: 'Informations diverses AEEMG',
                  value: prefs.generalEnabled,
                  onChanged: (v) => update(prefs.copyWith(generalEnabled: v)),
                ),
                const SizedBox(height: AppSpacing.md),
                const AeemgSectionHeader(title: 'Secours'),
                AeemgSwitchTile(
                  icon: Icons.sms_failed_outlined,
                  tint: AppColors.warning,
                  title: 'SMS de secours',
                  subtitle: 'Alerte par SMS si notification in-app manquée',
                  value: prefs.smsFallbackEnabled,
                  onChanged: (v) =>
                      update(prefs.copyWith(smsFallbackEnabled: v)),
                ),
              ];
            },
          );
    }

    return AeemgPage(
      title: 'Préférences d\'alertes',
      subtitle: 'Choisissez les notifications que vous souhaitez recevoir.',
      children: content,
    );
  }

  Future<void> _save(
    WidgetRef ref,
    String userId,
    NotificationPreferences updated,
  ) async {
    await ref
        .read(notificationPreferencesRepositoryProvider)
        .upsert(userId, updated);
    ref.invalidate(notificationPreferencesProvider);
  }
}
