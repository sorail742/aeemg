import 'package:supabase_flutter/supabase_flutter.dart';

class MosqueNeed {
  const MosqueNeed({
    required this.id,
    required this.title,
    this.description,
    required this.quantityNeeded,
    required this.quantityFulfilled,
    required this.status,
  });

  final String id;
  final String title;
  final String? description;
  final int quantityNeeded;
  final int quantityFulfilled;
  final String status;

  factory MosqueNeed.fromJson(Map<String, dynamic> json) => MosqueNeed(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        quantityNeeded: json['quantity_needed'] as int? ?? 1,
        quantityFulfilled: json['quantity_fulfilled'] as int? ?? 0,
        status: json['status'] as String? ?? 'open',
      );
}

class MosqueRepository {
  MosqueRepository(this._client);

  final SupabaseClient? _client;

  Future<List<MosqueNeed>> fetchNeeds() async {
    final rows = await _client
        ?.from('mosque_needs')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return (rows as List? ?? [])
        .map((e) => MosqueNeed.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> signUpVolunteer({
    required String userId,
    required String mission,
    DateTime? eventDate,
    String? notes,
  }) async {
    await _client?.from('volunteer_signups').insert({
      'user_id': userId,
      'mission': mission,
      'event_date': eventDate?.toIso8601String().split('T').first,
      'notes': notes,
    });
  }
}
