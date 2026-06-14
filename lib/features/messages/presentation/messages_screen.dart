import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/announcement_detail_dialog.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/messages_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: AppColors.background.withValues(alpha: 0.9),
          elevation: 0,
          title: Text('Messages', style: AppTypography.h2.copyWith(color: AppColors.white)),
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Groupes'),
              Tab(text: 'Annonces'),
            ],
          ),
        ),
        body: IslamicBackground(
          withPattern: true,
          child: const TabBarView(
            children: [
              _GroupsTab(),
              _AnnouncementsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(chatGroupsProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: AppColors.gold),
              ).animate().fade().scale(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Connectez-vous pour accéder aux groupes',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ).animate(delay: 100.ms).fade(),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.push('/login'),
              ).animate(delay: 200.ms).fade().slideY(begin: 0.2),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.emerald,
      backgroundColor: AppColors.cardSurface,
      onRefresh: () async => ref.invalidate(chatGroupsProvider),
      child: AsyncValueWidget(
        value: groupsAsync,
        empty: ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Aucun groupe disponible.', style: TextStyle(color: AppColors.textSecondary))),
          ],
        ),
        data: (groups) => ListView.separated(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 64,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final group = groups[index];
            final timeStr = DateFormat.Hm('fr').format(group.createdAt);
            return AeemgCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              onTap: () => context.push(
                '/messages/chat/${group.id}',
                extra: group.name ?? 'Discussion',
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.emerald.withValues(alpha: 0.2),
                        child: Icon(
                          group.isGroup ? Icons.groups : Icons.person,
                          color: AppColors.emerald,
                          size: 30,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name ?? 'Utilisateur',
                                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: AppTypography.caption.copyWith(color: AppColors.emerald),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.description ?? (group.isGroup ? 'Groupe de discussion' : 'Discussion privée'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 50 * index)).fade().slideX(begin: 0.05);
          },
        ),
      ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final user = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('d MMM yyyy', 'fr');

    return RefreshIndicator(
      color: AppColors.emerald,
      backgroundColor: AppColors.cardSurface,
      onRefresh: () async => ref.invalidate(announcementsProvider),
      child: AsyncValueWidget(
        value: announcementsAsync,
        empty: ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Aucune annonce pour le moment.', style: TextStyle(color: AppColors.textSecondary))),
          ],
        ),
        data: (announcements) => ListView.separated(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 64,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: announcements.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return AeemgCard(
              variant: announcement.isImportant
                  ? AeemgCardVariant.active
                  : AeemgCardVariant.primary,
              onTap: () async {
                if (user != null) {
                  await ref
                      .read(messagesRepositoryProvider)
                      .markAnnouncementRead(announcement.id, user.id);
                }
                if (context.mounted) {
                  await showAnnouncementDetail(context, announcement);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (announcement.isImportant ? AppColors.gold : AppColors.emerald).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          announcement.isImportant ? Icons.priority_high : Icons.campaign,
                          color: announcement.isImportant ? AppColors.gold : AppColors.emerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(announcement.title, style: AppTypography.h3),
                      ),
                      if (announcement.isImportant)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'URGENT',
                            style: AppTypography.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    announcement.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(announcement.createdAt),
                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 80 * index)).fade().slideX(begin: 0.05);
          },
        ),
      ),
    );
  }
}
