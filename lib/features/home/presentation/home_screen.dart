import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/announcement_detail_dialog.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_hero.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../events/presentation/event_detail_screen.dart';
import '../../messages/presentation/providers/messages_provider.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../islamic/presentation/widgets/prayer_times_widget.dart';
import 'providers/home_provider.dart';
import 'widgets/home_widgets.dart';

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

    final hijri = HijriCalendar.fromDate(now);
    var index = 0;
    Widget item(Widget child) => child.reveal(context, index: index++);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: SafeArea(
          bottom: false,
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
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                item(HomeTopBar(unreadCount: unreadCount)),
                const SizedBox(height: AppSpacing.md),
                item(
                  AeemgHero(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASSALAMOU ALAYKOUM',
                          style: AppTypography.overline.copyWith(
                            color: AppColors.goldLight,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(_greeting(now), style: AppTypography.display),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          toBeginningOfSentenceCase(
                            DateFormat('EEEE d MMMM y', 'fr').format(now),
                          ),
                          style: AppTypography.body.copyWith(
                            color: AppColors.lightEmerald,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        HomeHeroChip(
                          icon: Icons.nightlight_round,
                          label:
                              '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                item(const PrayerTimesWidget()),
                const SizedBox(height: AppSpacing.lg),

                item(
                  Row(
                    children: [
                      HomeQuickAccess(
                        icon: Icons.menu_book_rounded,
                        label: 'Coran',
                        tint: AppColors.brightGreen,
                        onTap: () => context.push('/quran'),
                      ),
                      HomeQuickAccess(
                        icon: Icons.format_quote_rounded,
                        label: 'Hadiths',
                        tint: AppColors.gold,
                        onTap: () => context.push('/hadith'),
                      ),
                      HomeQuickAccess(
                        icon: Icons.event_rounded,
                        label: 'Agenda',
                        tint: AppColors.info,
                        onTap: () => context.go('/agenda'),
                      ),
                      HomeQuickAccess(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'Dons',
                        tint: AppColors.violet,
                        onTap: () => context.push('/donations'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                item(
                  verseAsync.when(
                    data: (verse) => AeemgAccentCard(
                      title: verse.title ?? 'Rappel du jour',
                      body: verse.body,
                      source: verse.source,
                      onTap: () => context.push('/hadith'),
                    ),
                    loading: () => const AeemgSkeletonTile(),
                    error: (_, _) => const AeemgAccentCard(
                      title: 'Rappel du jour',
                      body:
                          'Et cramponnez-vous tous ensemble au câble d\'Allah et ne vous divisez pas.',
                      source: 'Coran 3:103',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                item(const AeemgSectionHeader(title: 'Dernières annonces')),
                item(
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
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: HomeListCard(
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
                    loading: () => const AeemgSkeletonTile(),
                    error: (e, _) => AeemgEmptyState(
                      compact: true,
                      icon: Icons.cloud_off_outlined,
                      title: 'Annonces indisponibles',
                      message: friendlySupabaseError(e),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                item(const AeemgSectionHeader(title: 'Prochain événement')),
                item(
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
                      return HomeListCard(
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
                    loading: () => const AeemgSkeletonTile(),
                    error: (e, _) => AeemgEmptyState(
                      compact: true,
                      icon: Icons.cloud_off_outlined,
                      title: 'Agenda indisponible',
                      message: friendlySupabaseError(e),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
