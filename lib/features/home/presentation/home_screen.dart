import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/announcement_detail_dialog.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../events/presentation/event_detail_screen.dart';
import '../../messages/presentation/providers/messages_provider.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../islamic/presentation/widgets/prayer_times_widget.dart';
import 'providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _greeting(DateTime now) {
    if (now.hour < 5 || now.hour >= 18) return 'Bonsoir';
    if (now.hour < 12) return 'Bonjour';
    return 'Bon après-midi';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(dynamicReminderProvider);
    final announcementsAsync = ref.watch(homeAnnouncementsProvider);
    final nextEventAsync = ref.watch(homeNextEventProvider);
    final user = ref.watch(currentUserProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadAsync.maybeWhen(data: (c) => c, orElse: () => 0);
    final dateFormat = DateFormat('EEE d MMM · HH:mm', 'fr');
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AEEMG',
          style: AppTypography.h3.copyWith(letterSpacing: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.error,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: IslamicBackground(
        withPattern: true,
        child: RefreshIndicator(
          color: AppColors.emerald,
          onRefresh: () async {
            ref.invalidate(homeAnnouncementsProvider);
            ref.invalidate(homeNextEventProvider);
            ref.invalidate(dynamicReminderProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Text(_greeting(now), style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                toBeginningOfSentenceCase(
                  DateFormat('EEEE d MMMM y', 'fr').format(now),
                ),
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              const PrayerTimesWidget(),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  _QuickAccess(
                    icon: Icons.menu_book_outlined,
                    label: 'Coran',
                    onTap: () => context.push('/quran'),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  _QuickAccess(
                    icon: Icons.format_quote_outlined,
                    label: 'Hadiths',
                    onTap: () => context.push('/hadith'),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  _QuickAccess(
                    icon: Icons.event_outlined,
                    label: 'Agenda',
                    onTap: () => context.go('/agenda'),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  _QuickAccess(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Dons',
                    onTap: () => context.push('/donations'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              verseAsync.when(
                data: (verse) => AeemgAccentCard(
                  title: verse.title ?? 'Rappel du jour',
                  body: verse.body,
                  source: verse.source,
                  onTap: () => context.push('/hadith'),
                ),
                loading: () => const AeemgAccentCard(
                  title: 'Rappel du jour',
                  body: 'Chargement…',
                ),
                error: (_, _) => const AeemgAccentCard(
                  title: 'Rappel du jour',
                  body:
                      'Et cramponnez-vous tous ensemble au câble d\'Allah et ne vous divisez pas.',
                  source: 'Coran 3:103',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              const AeemgSectionHeader(title: 'Dernières annonces'),
              announcementsAsync.when(
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return const AeemgEmptyState(
                      compact: true,
                      icon: Icons.campaign_outlined,
                      title: 'Aucune annonce',
                      message: 'Les annonces du bureau apparaîtront ici.',
                    );
                  }
                  return Column(
                    children: [
                      for (final a in announcements)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ListCard(
                            icon: Icons.campaign_outlined,
                            highlight: a.isImportant,
                            title: a.title,
                            subtitle: a.content,
                            onTap: () async {
                              if (user != null) {
                                await ref
                                    .read(messagesRepositoryProvider)
                                    .markAnnouncementRead(a.id, user.id);
                              }
                              if (context.mounted) {
                                await showAnnouncementDetail(context, a);
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const _SectionLoading(),
                error: (e, _) => AeemgEmptyState(
                  compact: true,
                  icon: Icons.cloud_off_outlined,
                  title: 'Annonces indisponibles',
                  message: friendlySupabaseError(e),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              const AeemgSectionHeader(title: 'Prochain événement'),
              nextEventAsync.when(
                data: (event) {
                  if (event == null) {
                    return const AeemgEmptyState(
                      compact: true,
                      icon: Icons.event_available_outlined,
                      title: 'Aucun événement à venir',
                      message:
                          'Consultez l\'agenda pour les activités passées.',
                    );
                  }
                  return _ListCard(
                    icon: Icons.event_outlined,
                    highlight: true,
                    title: event.title,
                    subtitle:
                        '${event.typeLabel} · ${dateFormat.format(event.startsAt)}',
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        ),
                  );
                },
                loading: () => const _SectionLoading(),
                error: (e, _) => AeemgEmptyState(
                  compact: true,
                  icon: Icons.cloud_off_outlined,
                  title: 'Agenda indisponible',
                  message: friendlySupabaseError(e),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms),
        ),
      ),
    );
  }
}

/// Raccourci de l'accueil : quatre tuiles de même largeur, une seule couleur d'icône.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AeemgCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.brightGreen, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de liste en carte : pastille d'icône, titre, sous-titre sur deux lignes.
class _ListCard extends StatelessWidget {
  const _ListCard({
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

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      child: LinearProgressIndicator(minHeight: 2),
    );
  }
}
