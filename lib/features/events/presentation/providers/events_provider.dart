import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/offline_cache_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/events_repository.dart';
import '../../data/models/event.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(supabaseClientProvider));
});

String _monthKey(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

final eventsForMonthProvider =
    FutureProvider.family<List<AeemgEvent>, DateTime>((ref, month) async {
  final cache = ref.read(offlineCacheProvider);
  final key = _monthKey(month);
  try {
    final events =
        await ref.read(eventsRepositoryProvider).fetchEvents(month: month);
    await cache.saveEventsMonth(
      key,
      events
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'description': e.description,
              'event_type': e.eventType,
              'location': e.location,
              'starts_at': e.startsAt.toIso8601String(),
              'ends_at': e.endsAt?.toIso8601String(),
              'is_recurring': e.isRecurring,
              'created_at': e.createdAt.toIso8601String(),
            },
          )
          .toList(),
    );
    return events;
  } catch (_) {
    final cached = cache.loadEventsMonth(key);
    if (cached.isEmpty) rethrow;
    return cached.map((e) => AeemgEvent.fromJson(e)).toList();
  }
});

final nextEventProvider = FutureProvider<AeemgEvent?>((ref) async {
  return ref.read(eventsRepositoryProvider).fetchNextEvent();
});

final rsvpCountProvider = FutureProvider.family<int, String>((ref, eventId) {
  return ref.read(eventsRepositoryProvider).fetchRsvpCount(eventId);
});
