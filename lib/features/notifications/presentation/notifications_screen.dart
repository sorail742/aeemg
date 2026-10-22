import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_page.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/notifications_repository.dart';
import 'providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final List<Widget> content;
    if (user == null) {
      content = [
        AeemgEmptyState(
          compact: true,
          icon: Icons.notifications_off_outlined,
          title: 'Notifications personnelles',
          message:
              'Connectez-vous pour recevoir vos alertes événements et messages.',
          actionLabel: 'Se connecter',
          onAction: () => context.push('/login'),
        ),
      ];
    } else {
      content = ref
          .watch(notificationsProvider)
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
                title: 'Notifications indisponibles',
                message: friendlySupabaseError(error),
              ),
            ],
            data: (notifications) => notifications.isEmpty
                ? const [
                    AeemgEmptyState(
                      compact: true,
                      icon: Icons.notifications_none_rounded,
                      title: 'Tout est lu',
                      message: 'Aucune notification pour le moment.',
                    ),
                  ]
                : [
                    for (final n in notifications)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _NotificationCard(
                          notification: n,
                          onTap: () async {
                            if (n.isRead) return;
                            await ref
                                .read(notificationsRepositoryProvider)
                                .markAsRead(n.id);
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                          },
                        ),
                      ),
                  ],
          );
    }

    return AeemgPage(
      title: 'Notifications',
      actions: [
        AeemgRoundIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Préférences',
          onPressed: () => context.push('/notifications/settings'),
        ),
      ],
      onRefresh: user == null
          ? null
          : () async => ref.invalidate(notificationsProvider),
      children: content,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final tint = unread ? AppColors.brightGreen : AppColors.textTertiary;
    return AeemgCard(
      variant: unread ? AeemgCardVariant.accent : AeemgCardVariant.primary,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              unread
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: tint,
              size: 20,
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
                        notification.title,
                        style: AppTypography.h4.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (unread)
                      Semantics(
                        label: 'Non lue',
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brightGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(notification.body, style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat(
                    'd MMM · HH:mm',
                    'fr',
                  ).format(notification.createdAt),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
