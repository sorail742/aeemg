import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final dateFormat = DateFormat('d MMM · HH:mm', 'fr');

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Notifications', style: AppTypography.h2.copyWith(color: AppColors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.gold),
            tooltip: 'Préférences',
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: IslamicBackground(
        withPattern: true,
        child: user == null
            ? _GuestPrompt(onLogin: () => context.push('/login'))
            : RefreshIndicator(
                color: AppColors.emerald,
                backgroundColor: AppColors.cardSurface,
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: AsyncValueWidget(
                  value: notificationsAsync,
                  empty: ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 80),
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none, size: 64, color: AppColors.textTertiary),
                            const SizedBox(height: AppSpacing.md),
                            Text('Aucune notification pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  data: (notifications) => ListView.separated(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final isUnread = !n.isRead;
                      return AeemgCard(
                        variant: isUnread ? AeemgCardVariant.active : AeemgCardVariant.primary,
                        onTap: () async {
                          if (isUnread) {
                            await ref
                                .read(notificationsRepositoryProvider)
                                .markAsRead(n.id);
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                          }
                        },
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isUnread ? AppColors.emerald : AppColors.textTertiary).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isUnread ? Icons.notifications_active : Icons.notifications_none,
                                color: isUnread ? AppColors.emerald : AppColors.textTertiary,
                                size: 22,
                              ),
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
                                          n.title,
                                          style: AppTypography.h3.copyWith(
                                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.emerald,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    n.body,
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(n.createdAt),
                                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: Duration(milliseconds: 60 * index)).fade().slideX(begin: 0.05);
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textTertiary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textSecondary),
            ).animate().fade().scale(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Notifications personnelles',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fade(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Connectez-vous pour recevoir vos alertes événements et messages.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate(delay: 150.ms).fade(),
            const SizedBox(height: AppSpacing.xl),
            AeemgPrimaryButton(
              label: 'Se connecter',
              icon: Icons.email_outlined,
              onPressed: onLogin,
            ).animate(delay: 200.ms).fade().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
