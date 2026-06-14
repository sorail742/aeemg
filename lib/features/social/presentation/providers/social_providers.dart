import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/social_repository.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw Exception('Supabase client is not initialized');
  return SocialRepository(client);
});

final feedProvider = StateNotifierProvider<FeedNotifier, AsyncValue<List<PostModel>>>((ref) {
  return FeedNotifier(ref.watch(socialRepositoryProvider));
});

class FeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final SocialRepository _repository;

  FeedNotifier(this._repository) : super(const AsyncValue.loading()) {
    refreshFeed();
  }

  Future<void> refreshFeed() async {
    state = const AsyncValue.loading();
    try {
      final posts = await _repository.fetchFeed();
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPost(String content, File? imageFile) async {
    try {
      final newPost = await _repository.createPost(content: content, imageFile: imageFile);
      if (state is AsyncData) {
        final currentPosts = state.value!;
        state = AsyncValue.data([newPost, ...currentPosts]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleLike(PostModel post) async {
    if (state is! AsyncData) return;
    
    final currentPosts = state.value!;
    final index = currentPosts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final isLiked = post.isLikedByMe;
    
    // Optimistic update
    final updatedPost = post.copyWith(
      isLikedByMe: !isLiked,
      likesCount: post.likesCount + (isLiked ? -1 : 1),
    );
    
    final newPosts = List<PostModel>.from(currentPosts);
    newPosts[index] = updatedPost;
    state = AsyncValue.data(newPosts);

    try {
      if (isLiked) {
        await _repository.unlikePost(post.id);
      } else {
        await _repository.likePost(post.id);
      }
    } catch (e) {
      // Revert if error
      newPosts[index] = post;
      state = AsyncValue.data(newPosts);
    }
  }

  void incrementCommentCount(String postId) {
    if (state is! AsyncData) return;
    final currentPosts = state.value!;
    final index = currentPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final newPosts = List<PostModel>.from(currentPosts);
      final p = newPosts[index];
      newPosts[index] = p.copyWith(commentsCount: p.commentsCount + 1);
      state = AsyncValue.data(newPosts);
    }
  }

  Future<void> deletePost(String postId) async {
    if (state is! AsyncData) return;
    final currentPosts = state.value!;
    final newPosts = currentPosts.where((p) => p.id != postId).toList();
    state = AsyncValue.data(newPosts);
    
    try {
      await _repository.deletePost(postId);
    } catch (e) {
      state = AsyncValue.data(currentPosts);
    }
  }
}

final postCommentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, postId) async {
  return ref.watch(socialRepositoryProvider).fetchComments(postId);
});
