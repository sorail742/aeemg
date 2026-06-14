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
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../events/presentation/event_detail_screen.dart';
import '../../messages/presentation/providers/messages_provider.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../islamic/presentation/widgets/prayer_times_widget.dart';
import 'providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(dynamicReminderProvider);
    final announcementsAsync = ref.watch(homeAnnouncementsProvider);
    final nextEventAsync = ref.watch(homeNextEventProvider);
    final user = ref.watch(currentUserProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadAsync.maybeWhen(data: (c) => c, orElse: () => 0);
    final dateFormat = DateFormat('d MMM · HH:mm', 'fr');

    String getWelcomeMessage() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Bonjour ☀️';
      } else if (hour < 18) {
        return 'Bonne après-midi 🌤️';
      } else {
        return 'Bonsoir 🌙';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AEEMG',
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.error,
              label: Text('$unreadCount', style: const TextStyle(color: Colors.white)),
              child: const Icon(Icons.notifications_outlined, color: AppColors.white),
            ),
            onPressed: () => context.push('/notifications'),
          ),
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
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 100,
            ),
            children: [
              // ── Welcome Message ──
              Text(
                getWelcomeMessage(),
                style: AppTypography.h1.copyWith(color: AppColors.emerald),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: AppSpacing.sm),
              
              // ── Prayer Times ──
              const PrayerTimesWidget()
                  .animate(delay: 200.ms)
                  .fade(duration: 400.ms)
                  .scale(begin: const Offset(0.95, 0.95)),
              
              const SizedBox(height: AppSpacing.lg),

              // ── Quick Access Row (Glassmorphism shortcuts) ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _QuickAccessIcon(
                      icon: Icons.menu_book,
                      label: 'Coran',
                      color: AppColors.emerald,
                      onTap: () => context.push('/quran'),
                    ),
                    _QuickAccessIcon(
                      icon: Icons.format_quote,
                      label: 'Hadiths',
                      color: AppColors.gold,
                      onTap: () => context.push('/hadith'),
                    ),
                    _QuickAccessIcon(
                      icon: Icons.event,
                      label: 'Agenda',
                      color: AppColors.brightGreen,
                      onTap: () => context.push('/agenda'),
                    ),
                    _QuickAccessIcon(
                      icon: Icons.volunteer_activism,
                      label: 'Dons',
                      color: AppColors.error, // Reddish
                      onTap: () => context.push('/donations'),
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fade().slideX(begin: 0.1),

              const SizedBox(height: AppSpacing.lg),
              
              // ── Inspiration of the Day ──
              verseAsync.when(
                data: (verse) => AeemgAccentCard(
                  title: verse.title ?? 'Rappel Islamique',
                  body: verse.body,
                  source: verse.source,
                  onTap: () => context.push('/hadith'),
                ),
                loading: () => const AeemgAccentCard(
                  title: 'Rappel Islamique',
                  body: 'Chargement…',
                ),
                error: (_, _) => const AeemgAccentCard(
                  title: 'Rappel Islamique',
                  body: 'Et cramponnez-vous tous ensemble au câble d\'Allah et ne vous divisez pas.',
                  source: 'Coran 3:103',
                ),
              ).animate(delay: 400.ms).fade().slideY(begin: 0.1),
              
              const SizedBox(height: AppSpacing.xl),
              
              // ── Announcements ──
              Text('Dernières annonces', style: AppTypography.h2)
                  .animate(delay: 500.ms).fade(),
              const SizedBox(height: AppSpacing.sm),
              announcementsAsync.when(
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return const AeemgCard(
                      child: Text('Aucune annonce pour le moment', style: TextStyle(color: Colors.white70)),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: announcements.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final a = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AeemgCard(
                          variant: a.isImportant
                              ? AeemgCardVariant.active
                              : AeemgCardVariant.primary,
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (a.isImportant ? AppColors.gold : AppColors.emerald).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.campaign,
                                  color: a.isImportant ? AppColors.gold : AppColors.emerald,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.title, style: AppTypography.h3),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      a.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 500 + (idx * 100))).fade().slideX(begin: 0.05);
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(color: AppColors.emerald),
                error: (e, _) => AeemgCard(
                  child: Text(friendlySupabaseError(e), style: const TextStyle(color: Colors.red)),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // ── Next Event ──
              Text('Prochain événement', style: AppTypography.h2)
                  .animate(delay: 600.ms).fade(),
              const SizedBox(height: AppSpacing.sm),
              nextEventAsync.when(
                data: (event) {
                  if (event == null) {
                    return const AeemgCard(
                      child: Text('Aucun événement à venir', style: TextStyle(color: Colors.white70)),
                    );
                  }
                  return AeemgCard(
                    variant: AeemgCardVariant.active,
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailScreen(event: event),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brightGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event, color: AppColors.brightGreen),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: AppTypography.h3),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${event.typeLabel} · ${dateFormat.format(event.startsAt)}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.emerald),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ).animate(delay: 700.ms).fade().scale(begin: const Offset(0.98, 0.98));
                },
                loading: () => const LinearProgressIndicator(color: AppColors.emerald),
                error: (e, _) => AeemgCard(
                  child: Text(friendlySupabaseError(e), style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessIcon extends StatelessWidget {
  const _QuickAccessIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.cardSurface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
