import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_avatar.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/aeemg_motion.dart';
import '../../data/models/post_model.dart';
import '../providers/social_providers.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;
  final bool isDetail;

  const PostCard({super.key, required this.post, this.isDetail = false});

  void _open(BuildContext context) =>
      context.push('/social/post/${post.id}', extra: post);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = post.author?.fullName ?? 'Membre AEEMG';

    return AeemgCard(
      padding: EdgeInsets.zero,
      onTap: isDetail ? null : () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                AeemgAvatar(name: author),
                const SizedBox(width: AppSpacing.smMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: AppTypography.h4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeago.format(post.createdAt, locale: 'fr'),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.smMd,
                AppSpacing.md,
                0,
              ),
              child: Text(post.content, style: AppTypography.bodyLarge),
            ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.smMd,
                AppSpacing.md,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const AeemgSkeleton(height: 200, radius: 0),
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                _LikeButton(
                  liked: post.isLikedByMe,
                  count: post.likesCount,
                  onTap: () => ref.read(feedProvider.notifier).toggleLike(post),
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentsCount}',
                  semantics: '${post.commentsCount} commentaires',
                  onTap: isDetail ? null : () => _open(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « J'aime » : le cœur se remplit avec un léger rebond.
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.base;
    return _ActionButton(
      semantics: liked ? "Je n'aime plus ($count)" : "J'aime ($count)",
      label: '$count',
      color: liked ? AppColors.error : AppColors.textSecondary,
      onTap: onTap,
      iconWidget: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.emphasized,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(liked),
          color: liked ? AppColors.error : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.semantics,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.color = AppColors.textSecondary,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String semantics;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget ?? Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
