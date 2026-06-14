import 'package:supabase_flutter/supabase_flutter.dart';

class IslamicContent {
  const IslamicContent({
    required this.id,
    required this.contentType,
    this.title,
    required this.body,
    this.source,
    this.translationPeul,
  });

  final String id;
  final String contentType;
  final String? title;
  final String body;
  final String? source;
  final String? translationPeul;

  factory IslamicContent.fromJson(Map<String, dynamic> json) => IslamicContent(
        id: json['id'] as String,
        contentType: json['content_type'] as String,
        title: json['title'] as String?,
        body: json['body'] as String,
        source: json['source'] as String?,
        translationPeul: json['translation_peul'] as String?,
      );
}

class IslamicRepository {
  IslamicRepository(this._client);

  final SupabaseClient? _client;

  Future<IslamicContent?> fetchTodayVerse() async {
    final row = await _client
        ?.from('islamic_contents')
        .select()
        .eq('content_type', 'verse')
        .eq('active_date', DateTime.now().toIso8601String().split('T').first)
        .maybeSingle();

    if (row != null) return IslamicContent.fromJson(row);

    final fallback = await _client
        ?.from('islamic_contents')
        .select()
        .eq('content_type', 'verse')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (fallback == null) return null;
    return IslamicContent.fromJson(fallback);
  }

  Future<List<IslamicContent>> fetchLibrary() async {
    final rows = await _client
        ?.from('islamic_contents')
        .select()
        .order('created_at', ascending: false);
    return (rows as List? ?? [])
        .map((e) => IslamicContent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> fetchFavoriteIds(String userId) async {
    final rows = await _client
        ?.from('islamic_favorites')
        .select('content_id')
        .eq('user_id', userId);
    return (rows as List? ?? [])
        .map((e) => (e as Map<String, dynamic>)['content_id'] as String)
        .toSet();
  }

  Future<void> addFavorite(String userId, String contentId) async {
    await _client?.from('islamic_favorites').insert({
      'user_id': userId,
      'content_id': contentId,
    });
  }

  Future<void> removeFavorite(String userId, String contentId) async {
    await _client
        ?.from('islamic_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('content_id', contentId);
  }
}
