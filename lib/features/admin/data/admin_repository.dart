import 'package:supabase_flutter/supabase_flutter.dart';

class BetaFeedbackSummary {
  const BetaFeedbackSummary({
    required this.count,
    required this.averageRating,
    required this.recent,
  });
  final int count;
  final double averageRating;
  final List<Map<String, dynamic>> recent;
}

class AdminStats {
  const AdminStats({
    required this.totalMembers,
    required this.newMembersThisMonth,
    required this.totalMessages,
    required this.totalDonations,
    required this.upcomingEvents,
    required this.pendingFeedbacks,
    required this.pendingEvents,
  });
  final int totalMembers;
  final int newMembersThisMonth;
  final int totalMessages;
  final double totalDonations;
  final int upcomingEvents;
  final int pendingFeedbacks;
  final int pendingEvents;
}

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient? _client;

  // ── Stats générales ───────────────────────────────────────────
  Future<AdminStats> fetchStats() async {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final membersRes = await _client?.from('profiles').select('id').count();
    final newMembersRes = await _client
        ?.from('profiles')
        .select('id')
        .gte('created_at', firstOfMonth)
        .count();
    final messagesRes = await _client?.from('messages').select('id').count();
    final eventsRes = await _client
        ?.from('events')
        .select('id')
        .gte('starts_at', now.toIso8601String())
        .eq('is_approved', true)
        .count();
    final pendingEventsRes = await _client
        ?.from('events')
        .select('id')
        .eq('is_approved', false)
        .count();
    final feedbacksRes = await _client?.from('feedback').select('id').count();
    final donationsRes =
        await _client?.from('donations').select('amount').limit(1000);

    final totalDonations = ((donationsRes as List?) ?? [])
        .fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));

    return AdminStats(
      totalMembers: membersRes?.count ?? 0,
      newMembersThisMonth: newMembersRes?.count ?? 0,
      totalMessages: messagesRes?.count ?? 0,
      totalDonations: totalDonations,
      upcomingEvents: eventsRes?.count ?? 0,
      pendingFeedbacks: feedbacksRes?.count ?? 0,
      pendingEvents: pendingEventsRes?.count ?? 0,
    );
  }

  // ── Membres ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchAllMembers() async {
    final res = await _client
        ?.from('profiles')
        .select('id, full_name, phone, section, role, created_at, avatar_url')
        .order('created_at', ascending: false)
        .limit(200);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> updateMemberRole(String userId, String role) async {
    await _client?.from('profiles').update({'role': role}).eq('id', userId);
  }

  Future<void> deleteMember(String userId) async {
    await _client?.from('profiles').delete().eq('id', userId);
  }

  // ── Annonces ─────────────────────────────────────────────────
  // La table announcements utilise "content" pas "body", et "is_important" pas "is_published"
  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final res = await _client
        ?.from('announcements')
        .select('id, title, content, created_at, is_important, is_published')
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    bool isImportant = false,
  }) async {
    final userId = _client?.auth.currentUser?.id;
    await _client?.from('announcements').insert({
      'title': title,
      'content': content,
      'author_id': userId,
      'is_important': isImportant,
      'is_published': true,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client?.from('announcements').delete().eq('id', id);
  }

  // ── Événements ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final res = await _client
        ?.from('events')
        .select('id, title, starts_at, ends_at, location, event_type, is_approved, description')
        .order('starts_at', ascending: true)
        .limit(100);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> approveEvent(String id) async {
    await _client
        ?.from('events')
        .update({'is_approved': true}).eq('id', id);
  }

  Future<void> deleteEvent(String id) async {
    await _client?.from('events').delete().eq('id', id);
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startsAt,
    required String location,
    String eventType = 'other',
  }) async {
    final userId = _client?.auth.currentUser?.id;
    await _client?.from('events').insert({
      'title': title,
      'description': description,
      'starts_at': startsAt.toIso8601String(),
      'location': location,
      'event_type': eventType,
      'created_by': userId,
      'is_approved': true, // Le staff crée des événements pré-approuvés
    });
  }

  // ── Dons ─────────────────────────────────────────────────────
  // La table donations n'a pas donor_name — on rejoint profiles
  Future<List<Map<String, dynamic>>> fetchDonations() async {
    final res = await _client
        ?.from('donations')
        .select('id, amount, category, status, payment_method, created_at, is_anonymous, user_id, profiles(full_name, phone)')
        .order('created_at', ascending: false)
        .limit(100);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  // ── Rapports mensuels ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchMonthlyReports() async {
    final res = await _client
        ?.from('monthly_reports')
        .select('id, year, month, total_income, total_expense, is_published, published_at, created_at')
        .order('year', ascending: false)
        .order('month', ascending: false)
        .limit(24);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> createFinanceReport({
    required int year,
    required int month,
    required double totalIncome,
    required double totalExpense,
  }) async {
    await _client?.from('monthly_reports').upsert({
      'year': year,
      'month': month,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'is_published': true,
      'published_at': DateTime.now().toIso8601String(),
    }, onConflict: 'year,month');
  }

  // ── Modération Social ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final res = await _client
        ?.from('posts')
        .select('id, content, image_url, likes_count, comments_count, created_at, profiles!posts_author_id_fkey(full_name, avatar_url)')
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> deletePost(String postId) async {
    await _client?.from('posts').delete().eq('id', postId);
  }

  // ── Bibliothèque Islamique ────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchIslamicContents() async {
    final res = await _client
        ?.from('islamic_contents')
        .select('id, title, body, content_type, source, active_date, created_at')
        .order('created_at', ascending: false)
        .limit(100);
    return (res as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> createIslamicContent({
    required String title,
    required String body,
    required String contentType,
    String? source,
    String? translationPeul,
    DateTime? activeDate,
  }) async {
    await _client?.from('islamic_contents').insert({
      'title': title,
      'body': body,
      'content_type': contentType,
      'source': source,
      'translation_peul': translationPeul,
      'active_date': (activeDate ?? DateTime.now()).toIso8601String().split('T').first,
    });
  }

  Future<void> deleteIslamicContent(String id) async {
    await _client?.from('islamic_contents').delete().eq('id', id);
  }

  // ── Feedbacks ─────────────────────────────────────────────────
  Future<BetaFeedbackSummary> fetchBetaSummary() async {
    final rows = await _client
        ?.from('feedback')
        .select('message, rating, created_at')
        .order('created_at', ascending: false)
        .limit(20);

    final list = (rows as List? ?? []).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return const BetaFeedbackSummary(count: 0, averageRating: 0, recent: []);
    }
    final ratings =
        list.map((e) => e['rating'] as int?).whereType<int>().toList();
    final avg = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    return BetaFeedbackSummary(
      count: list.length,
      averageRating: avg,
      recent: list,
    );
  }
}
