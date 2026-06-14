import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../data/models/post_model.dart';
import '../providers/social_providers.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;
  final bool isDetail;

  const PostCard({
    super.key,
    required this.post,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AeemgCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: isDetail ? null : () => context.push('/social/post/${post.id}', extra: post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.emerald,
                child: Text(
                  (post.author?.fullName ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author?.fullName ?? 'Utilisateur',
                      style: AppTypography.h3,
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
          const SizedBox(height: AppSpacing.md),
          Text(
            post.content,
            style: AppTypography.body,
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: AppSpacing.smMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              InkWell(
                onTap: () => ref.read(feedProvider.notifier).toggleLike(post),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                        color: post.isLikedByMe ? AppColors.error : AppColors.warmGray,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              InkWell(
                onTap: isDetail ? null : () => context.push('/social/post/${post.id}', extra: post),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.warmGray,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
