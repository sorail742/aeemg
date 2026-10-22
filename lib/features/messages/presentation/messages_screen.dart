import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/announcement_detail_dialog.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_pill_tab_bar.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/chat_models.dart';
import 'providers/messages_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IslamicBackground(
          withPattern: true,
          child: Column(
            children: [
              // Pas d'AppBar : en-tête sous la barre d'état.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + MediaQuery.paddingOf(context).top,
                  AppSpacing.md,
                  AppSpacing.smMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AeemgRoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Retour',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                        ),
                        const SizedBox(width: AppSpacing.smMd),
                        Expanded(
                          child: Text('Messages', style: AppTypography.h1),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AeemgPillTabBar(labels: ['Groupes', 'Annonces']),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [_GroupsTab(), _AnnouncementsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liste défilante commune aux deux onglets (rafraîchissement par glissement).
class _TabList extends StatelessWidget {
  const _TabList({required this.onRefresh, required this.children});

  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.emerald,
      backgroundColor: AppColors.cardSurface,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: children,
      ),
    );
  }
}

const _loading = [
  AeemgSkeletonTile(),
  SizedBox(height: AppSpacing.sm),
  AeemgSkeletonTile(),
  SizedBox(height: AppSpacing.sm),
  AeemgSkeletonTile(),
];

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return _TabList(
        onRefresh: () async {},
        children: [
          AeemgEmptyState(
            compact: true,
            icon: Icons.lock_outline_rounded,
            title: 'Groupes réservés aux membres',
            message: 'Connectez-vous pour rejoindre les discussions.',
            actionLabel: 'Se connecter',
            onAction: () => context.push('/login'),
          ),
        ],
      );
    }

    final groupsAsync = ref.watch(chatGroupsProvider);
    return _TabList(
      onRefresh: () async => ref.invalidate(chatGroupsProvider),
      children: groupsAsync.when(
        loading: () => _loading,
        error: (error, _) => [
          AeemgEmptyState(
            compact: true,
            icon: Icons.cloud_off_outlined,
            title: 'Discussions indisponibles',
            message: friendlySupabaseError(error),
          ),
        ],
        data: (groups) => groups.isEmpty
            ? const [
                AeemgEmptyState(
                  compact: true,
                  icon: Icons.forum_outlined,
                  title: 'Aucun groupe pour le moment',
                  message:
                      'Les groupes du bureau et de votre section apparaîtront ici.',
                ),
              ]
            : [
                for (var i = 0; i < groups.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GroupTile(
                      group: groups[i],
                    ).reveal(context, index: i),
                  ),
              ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final ChatGroup group;

  @override
  Widget build(BuildContext context) {
    final name = group.name ?? 'Discussion';
    final tint = group.isGroup ? AppColors.brightGreen : AppColors.info;
    return AeemgCard(
      onTap: () => context.push('/messages/chat/${group.id}', extra: name),
      padding: const EdgeInsets.all(AppSpacing.smMd),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.28),
                  tint.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: tint.withValues(alpha: 0.35)),
            ),
            child: Icon(
              group.isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: tint,
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.h4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM', 'fr').format(group.createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  group.description ??
                      (group.isGroup
                          ? 'Groupe de discussion'
                          : 'Discussion privée'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
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

    return _TabList(
      onRefresh: () async => ref.invalidate(announcementsProvider),
      children: announcementsAsync.when(
        loading: () => _loading,
        error: (error, _) => [
          AeemgEmptyState(
            compact: true,
            icon: Icons.cloud_off_outlined,
            title: 'Annonces indisponibles',
            message: friendlySupabaseError(error),
          ),
        ],
        data: (announcements) => announcements.isEmpty
            ? const [
                AeemgEmptyState(
                  compact: true,
                  icon: Icons.campaign_outlined,
                  title: 'Aucune annonce pour le moment',
                  message: 'Les annonces du bureau apparaîtront ici.',
                ),
              ]
            : [
                for (var i = 0; i < announcements.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AnnouncementCard(
                      announcement: announcements[i],
                      onTap: () async {
                        final a = announcements[i];
                        if (user != null) {
                          await ref
                              .read(messagesRepositoryProvider)
                              .markAnnouncementRead(a.id, user.id);
                        }
                        if (context.mounted) {
                          await showAnnouncementDetail(context, a);
                        }
                      },
                    ).reveal(context, index: i),
                  ),
              ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final Announcement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final important = announcement.isImportant;
    final tint = important ? AppColors.gold : AppColors.brightGreen;
    return AeemgCard(
      variant: important ? AeemgCardVariant.accent : AeemgCardVariant.primary,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  important
                      ? Icons.priority_high_rounded
                      : Icons.campaign_outlined,
                  color: tint,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Text(
                  announcement.title,
                  style: AppTypography.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (important)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    'IMPORTANT',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Text(
            announcement.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            DateFormat('d MMMM y', 'fr').format(announcement.createdAt),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
