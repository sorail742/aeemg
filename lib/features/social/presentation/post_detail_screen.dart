import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/supabase_errors.dart';
import '../../../../shared/widgets/ds/aeemg_avatar.dart';
import '../../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../../shared/widgets/ds/aeemg_section.dart';
import '../../../../shared/widgets/ds/islamic_background.dart';
import '../data/models/comment_model.dart';
import '../data/models/post_model.dart';
import 'providers/social_providers.dart';
import 'widgets/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.addComment(postId: widget.post.id, content: content);

      _commentController.clear();
      ref.read(feedProvider.notifier).incrementCommentCount(widget.post.id);
      ref.invalidate(postCommentsProvider(widget.post.id));

      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlySupabaseError(e))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Publication')),
      body: IslamicBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  PostCard(post: widget.post, isDetail: true).reveal(context),
                  const SizedBox(height: AppSpacing.lg),
                  const AeemgSectionHeader(title: 'Commentaires'),
                  ...commentsAsync.when(
                    loading: () => const [
                      AeemgSkeletonTile(),
                      SizedBox(height: AppSpacing.sm),
                      AeemgSkeletonTile(),
                    ],
                    error: (error, _) => [
                      AeemgEmptyState(
                        compact: true,
                        icon: Icons.cloud_off_outlined,
                        title: 'Commentaires indisponibles',
                        message: friendlySupabaseError(error),
                      ),
                    ],
                    data: (comments) => comments.isEmpty
                        ? const [
                            AeemgEmptyState(
                              compact: true,
                              icon: Icons.mode_comment_outlined,
                              title: 'Aucun commentaire',
                              message: 'Soyez le premier à réagir.',
                            ),
                          ]
                        : [
                            for (var i = 0; i < comments.length; i++)
                              _CommentBubble(
                                comment: comments[i],
                              ).reveal(context, index: i + 1),
                          ],
                  ),
                ],
              ),
            ),
            _CommentInput(
              controller: _commentController,
              isSubmitting: _isSubmitting,
              onSend: _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final author = comment.author?.fullName ?? 'Membre AEEMG';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.smMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AeemgAvatar(name: author, size: 34),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.smMd),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(AppRadius.large),
                  bottomLeft: Radius.circular(AppRadius.large),
                  bottomRight: Radius.circular(AppRadius.large),
                  topLeft: Radius.circular(AppRadius.small),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          author,
                          style: AppTypography.h4.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeago.format(comment.createdAt, locale: 'fr'),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(comment.content, style: AppTypography.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de saisie : champ arrondi et bouton d'envoi en dégradé.
class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.isSubmitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navBar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ajouter un commentaire…',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pillBorder,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBorder,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pillBorder,
                  borderSide: const BorderSide(color: AppColors.emerald),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 48,
            height: 48,
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.smMd),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AeemgPressable(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Envoyer',
                        onPressed: onSend,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
