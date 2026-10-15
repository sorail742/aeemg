import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/post_model.dart';
import 'models/comment_model.dart';

/// Erreur affichable telle quelle (`friendlySupabaseError` utilise `toString`).
class SocialUnavailableException implements Exception {
  const SocialUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialRepository {
  /// Nul quand Supabase n'est pas configuré : les lectures renvoient une liste vide
  /// au lieu de faire planter l'écran (écran gris en production).
  final SupabaseClient? _client;

  SocialRepository(this._client);

  SupabaseClient get _db =>
      _client ??
      (throw const SocialUnavailableException(
        'Le réseau social est indisponible pour le moment.',
      ));

  String get _userId =>
      _db.auth.currentUser?.id ??
      (throw const SocialUnavailableException(
        'Connectez-vous pour participer aux échanges.',
      ));

  Future<List<PostModel>> fetchFeed({int limit = 20, int offset = 0}) async {
    final client = _client;
    if (client == null) return [];
    final currentUserId = client.auth.currentUser?.id;

    final response = await client
        .from('posts')
        .select('*, profiles!posts_author_id_fkey(*), post_likes(user_id)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => PostModel.fromJson(e, currentUserId: currentUserId))
        .toList();
  }

  Future<PostModel> createPost({
    required String content,
    File? imageFile,
  }) async {
    final userId = _userId;
    String? imageUrl;

    if (imageFile != null) {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}_$userId.$fileExt';
      await _db.storage.from('social_images').upload(fileName, imageFile);
      imageUrl = _db.storage.from('social_images').getPublicUrl(fileName);
    }

    final response = await _db
        .from('posts')
        .insert({
          'author_id': userId,
          'content': content,
          'image_url': ?imageUrl,
        })
        .select('*, profiles!posts_author_id_fkey(*)')
        .single();

    return PostModel.fromJson(response, currentUserId: userId);
  }

  Future<void> likePost(String postId) async {
    final userId = _userId;
    await _db.from('post_likes').insert({'post_id': postId, 'user_id': userId});
  }

  Future<void> unlikePost(String postId) async {
    final userId = _userId;
    await _db.from('post_likes').delete().match({
      'post_id': postId,
      'user_id': userId,
    });
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    final client = _client;
    if (client == null) return [];
    final response = await client
        .from('post_comments')
        .select('*, profiles!post_comments_author_id_fkey(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = _userId;
    final response = await _db
        .from('post_comments')
        .insert({'post_id': postId, 'author_id': userId, 'content': content})
        .select('*, profiles!post_comments_author_id_fkey(*)')
        .single();

    return CommentModel.fromJson(response);
  }

  Future<void> deletePost(String postId) async {
    await _db.from('posts').delete().eq('id', postId);
  }

  Future<void> deleteComment(String commentId) async {
    await _db.from('post_comments').delete().eq('id', commentId);
  }
}
