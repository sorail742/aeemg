import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/notification_preferences_repository.dart';
import 'providers/notifications_provider.dart';

final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return NotificationPreferences.defaults;
  return ref
      .read(notificationPreferencesRepositoryProvider)
      .fetch(user.id);
});

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Préférences Alertes', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: user == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text('Connectez-vous pour gérer vos préférences.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : prefsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
                error: (e, _) => Center(child: Text(friendlySupabaseError(e), style: const TextStyle(color: AppColors.error))),
                data: (prefs) => ListView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.xl,
                  ),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4), width: 2),
                          boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.2), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.tune_outlined, size: 48, color: AppColors.emerald),
                      ).animate().scale(curve: Curves.easeOutBack),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Personnalisez vos alertes',
                      textAlign: TextAlign.center,
                      style: AppTypography.h2,
                    ).animate(delay: 100.ms).fade(),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Choisissez les notifications que vous souhaitez recevoir.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ).animate(delay: 150.ms).fade(),
                    const SizedBox(height: AppSpacing.xl),

                    _PrefTile(
                      icon: Icons.event,
                      color: AppColors.gold,
                      title: 'Événements',
                      subtitle: 'RSVP, rappels J-7, J-3, J-1',
                      value: prefs.eventsEnabled,
                      delay: 200,
                      onChanged: (v) => _update(ref, user.id, prefs, eventsEnabled: v),
                    ),
                    _PrefTile(
                      icon: Icons.account_balance_wallet,
                      color: AppColors.emerald,
                      title: 'Finances',
                      subtitle: 'Bilans publiés, campagnes',
                      value: prefs.financeEnabled,
                      delay: 300,
                      onChanged: (v) => _update(ref, user.id, prefs, financeEnabled: v),
                    ),
                    _PrefTile(
                      icon: Icons.forum,
                      color: const Color(0xFF0EA5E9), // Cyan
                      title: 'Messages',
                      subtitle: 'Annonces et discussions',
                      value: prefs.messagesEnabled,
                      delay: 400,
                      onChanged: (v) => _update(ref, user.id, prefs, messagesEnabled: v),
                    ),
                    _PrefTile(
                      icon: Icons.auto_stories,
                      color: AppColors.gold,
                      title: 'Rappels islamiques',
                      subtitle: 'Verset du jour, citations',
                      value: prefs.islamicEnabled,
                      delay: 500,
                      onChanged: (v) => _update(ref, user.id, prefs, islamicEnabled: v),
                    ),
                    _PrefTile(
                      icon: Icons.info_outline,
                      color: AppColors.textSecondary,
                      title: 'Général',
                      subtitle: 'Informations diverses AEEMG',
                      value: prefs.generalEnabled,
                      delay: 600,
                      onChanged: (v) => _update(ref, user.id, prefs, generalEnabled: v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.textTertiary, thickness: 0.3),
                    const SizedBox(height: AppSpacing.md),
                    _PrefTile(
                      icon: Icons.sms_failed_outlined,
                      color: AppColors.error,
                      title: 'SMS de secours',
                      subtitle: 'Alerte par SMS si notification in-app manquée',
                      value: prefs.smsFallbackEnabled,
                      delay: 700,
                      onChanged: (v) => _update(ref, user.id, prefs, smsFallbackEnabled: v),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _update(
    WidgetRef ref,
    String userId,
    NotificationPreferences prefs, {
    bool? eventsEnabled,
    bool? financeEnabled,
    bool? messagesEnabled,
    bool? islamicEnabled,
    bool? generalEnabled,
    bool? smsFallbackEnabled,
  }) async {
    final updated = prefs.copyWith(
      eventsEnabled: eventsEnabled,
      financeEnabled: financeEnabled,
      messagesEnabled: messagesEnabled,
      islamicEnabled: islamicEnabled,
      generalEnabled: generalEnabled,
      smsFallbackEnabled: smsFallbackEnabled,
    );
    await ref
        .read(notificationPreferencesRepositoryProvider)
        .upsert(userId, updated);
    ref.invalidate(notificationPreferencesProvider);
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
    required this.delay,
  });

  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final Color color;
  final ValueChanged<bool> onChanged;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AeemgCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h3),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.emerald,
              activeTrackColor: AppColors.emerald.withValues(alpha: 0.3),
            ),
          ],
        ),
      ).animate(delay: delay.ms).fade().slideY(begin: 0.1),
    );
  }
}
