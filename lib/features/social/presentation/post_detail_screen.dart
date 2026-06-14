import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                PostCard(post: widget.post, isDetail: true),
                const SizedBox(height: AppSpacing.lg),
                Text('Commentaires', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                commentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Erreur : $err')),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(child: Text('Aucun commentaire. Soyez le premier !'));
                    }
                    return Column(
                      children: comments.map((comment) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AeemgCard(
                          padding: const EdgeInsets.all(AppSpacing.smMd),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.darkTeal,
                                child: Text(
                                  (comment.author?.fullName ?? 'A')[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.white, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.smMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          comment.author?.fullName ?? 'Utilisateur',
                                          style: AppTypography.h3.copyWith(fontSize: 14),
                                        ),
                                        Text(
                                          timeago.format(comment.createdAt, locale: 'fr'),
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(comment.content, style: AppTypography.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.sm,
              bottom: AppSpacing.sm + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              border: Border(top: BorderSide(color: AppColors.darkCharcoal)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.send, color: AppColors.brightGreen),
                        onPressed: _submitComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
