import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/islamic_background.dart';
import 'providers/social_providers.dart';
import 'widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Réseau Social', style: AppTypography.h2.copyWith(color: AppColors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.gold),
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.emerald),
            onPressed: () => context.push('/social/create'),
          ),
        ],
      ),
      body: IslamicBackground(
        withPattern: true,
        child: RefreshIndicator(
          color: AppColors.emerald,
          backgroundColor: AppColors.cardSurface,
          onRefresh: () => ref.read(feedProvider.notifier).refreshFeed(),
          child: feedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
            error: (err, stack) => ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 80),
                Center(child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error))),
              ],
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 80),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.textTertiary.withValues(alpha: 0.1),
                            ),
                            child: const Icon(Icons.post_add, size: 64, color: AppColors.textTertiary),
                          ).animate().scale(curve: Curves.easeOutBack),
                          const SizedBox(height: AppSpacing.md),
                          Text('Aucune publication pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  return PostCard(post: posts[index]).animate(delay: Duration(milliseconds: 100 * index)).fade().slideY(begin: 0.1);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/social/create'),
        backgroundColor: AppColors.emerald,
        elevation: 4,
        child: const Icon(Icons.add, color: AppColors.white),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }
}
