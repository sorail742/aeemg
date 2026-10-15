import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/supabase_errors.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../../shared/widgets/ds/aeemg_section.dart';
import '../../../../shared/widgets/ds/islamic_background.dart';
import 'providers/social_providers.dart';
import 'widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    final List<Widget> content = feedAsync.when(
      loading: () => const [
        _PostSkeleton(),
        SizedBox(height: AppSpacing.md),
        _PostSkeleton(),
      ],
      error: (error, _) => [
        AeemgEmptyState(
          compact: true,
          icon: Icons.cloud_off_outlined,
          title: 'Fil indisponible',
          message: friendlySupabaseError(error),
          actionLabel: 'Réessayer',
          onAction: () => ref.read(feedProvider.notifier).refreshFeed(),
        ),
      ],
      data: (posts) => posts.isEmpty
          ? [
              AeemgEmptyState(
                compact: true,
                icon: Icons.forum_outlined,
                title: 'Aucune publication pour le moment',
                message:
                    'Lancez la conversation : une annonce, un rappel, une photo.',
                actionLabel: 'Publier',
                onAction: () => context.push('/social/create'),
              ),
            ]
          : [
              for (var i = 0; i < posts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PostCard(post: posts[i]).reveal(context, index: i + 2),
                ),
            ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.emerald,
            backgroundColor: AppColors.cardSurface,
            onRefresh: () => ref.read(feedProvider.notifier).refreshFeed(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                const _Header().reveal(context),
                const SizedBox(height: AppSpacing.lg),
                const _Composer().reveal(context, index: 1),
                const SizedBox(height: AppSpacing.lg),
                ...content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Communauté', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Partagez, encouragez, échangez.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        AeemgRoundIconButton(
          tooltip: 'Messages',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () => context.push('/messages'),
        ),
      ],
    );
  }
}

/// Zone de rédaction : ouvre l'écran de création (connexion demandée si besoin).
class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Créer une publication',
      excludeSemantics: true,
      child: AeemgCard(
        onTap: () => context.push('/social/create'),
        padding: const EdgeInsets.all(AppSpacing.smMd),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.brightGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Text(
                'Partagez quelque chose avec la communauté…',
                style: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.onPrimary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AeemgSkeleton(width: 40, height: 40, radius: 20),
              SizedBox(width: AppSpacing.smMd),
              AeemgSkeleton(width: 140),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AeemgSkeleton(),
          SizedBox(height: AppSpacing.sm),
          AeemgSkeleton(width: 220),
          SizedBox(height: AppSpacing.md),
          AeemgSkeleton(height: 140, radius: AppRadius.medium),
        ],
      ),
    );
  }
}
