import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../notifications/presentation/notification_settings_screen.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeCodeProvider);
    final user = ref.watch(currentUserProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(AppStrings.t('settings', locale), style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            _SectionHeader(title: AppStrings.t('language', locale)),
            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fr', label: Text('Français')),
                  ButtonSegment(value: 'ff', label: Text('Peul')),
                ],
                selected: {locale},
                onSelectionChanged: (set) => setAppLocale(ref, set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.emerald.withValues(alpha: 0.2);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.emerald;
                    }
                    return AppColors.textSecondary;
                  }),
                  side: WidgetStateProperty.all(BorderSide(color: AppColors.emerald.withValues(alpha: 0.5))),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ).animate().fade().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeader(title: 'Général'),
            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.offline_bolt_outlined, color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          AppStrings.t('offline_mode', locale),
                          style: AppTypography.h3,
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (v) {},
                        activeThumbColor: AppColors.emerald,
                        activeTrackColor: AppColors.emerald.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.t('offline_hint', locale),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fade().slideY(begin: 0.1),

            if (user != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: 'Notifications'),
              prefsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
                error: (_, _) => const SizedBox.shrink(),
                data: (prefs) => AeemgCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sms_outlined, color: AppColors.emerald, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SMS de secours', style: AppTypography.h3),
                            const SizedBox(height: 2),
                            Text(
                              'Recevoir un SMS si les notifications in-app échouent',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: prefs.smsFallbackEnabled,
                        onChanged: (v) async {
                          final updated = prefs.copyWith(smsFallbackEnabled: v);
                          await ref
                              .read(notificationPreferencesRepositoryProvider)
                              .upsert(user.id, updated);
                          ref.invalidate(notificationPreferencesProvider);
                        },
                        activeThumbColor: AppColors.emerald,
                        activeTrackColor: AppColors.emerald.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs, top: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.gold,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
