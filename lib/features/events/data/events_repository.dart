import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/event.dart';

class EventsRepository {
  EventsRepository(this._client);

  final SupabaseClient? _client;

  Future<List<AeemgEvent>> fetchEvents({DateTime? month}) async {
    final client = _client;
    if (client == null) return [];

    var query = client.from('events').select();
    if (month != null) {
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      query = query
          .gte('starts_at', start.toIso8601String())
          .lt('starts_at', end.toIso8601String());
    }

    final rows = await query.order('starts_at');
    return (rows as List)
        .map((e) => AeemgEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AeemgEvent?> fetchNextEvent() async {
    final client = _client;
    if (client == null) return null;

    final row = await client
        .from('events')
        .select()
        .gte('starts_at', DateTime.now().toIso8601String())
        .order('starts_at')
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return AeemgEvent.fromJson(row);
  }

  Future<int> fetchRsvpCount(String eventId) async {
    final rows = await _client
        ?.from('event_rsvps')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'going');
    return (rows as List?)?.length ?? 0;
  }

  Future<void> setRsvp({
    required String eventId,
    required String userId,
    required String status,
  }) async {
    await _client?.from('event_rsvps').upsert({
      'event_id': eventId,
      'user_id': userId,
      'status': status,
    });
  }
}
