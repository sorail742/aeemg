import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/offline_cache_provider.dart';
import '../../../events/data/models/event.dart';
import '../../../events/presentation/providers/events_provider.dart'
    show eventsRepositoryProvider;
import '../../../islamic/data/islamic_repository.dart';
import '../../../islamic/presentation/providers/islamic_provider.dart';
import '../../../messages/data/models/chat_models.dart';
import '../../../messages/presentation/providers/messages_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

final dynamicReminderProvider = StreamProvider.autoDispose<IslamicContent>((ref) async* {
  final jsonStr = await rootBundle.loadString('assets/data/hadiths.json');
  final List<dynamic> jsonList = jsonDecode(jsonStr);
  final hadiths = jsonList.map((e) => IslamicContent(
    id: e['id'].toString(),
    contentType: 'hadith',
    title: 'Rappel - ${e['category']}',
    body: e['text'],
    source: e['source'],
  )).toList();

  while (true) {
    final now = DateTime.now();
    final index = (now.millisecondsSinceEpoch ~/ (1000 * 60 * 30)) % hadiths.length;
    yield hadiths[index];
    
    final minutesToNext = 30 - (now.minute % 30);
    final secondsToWait = (minutesToNext * 60) - now.second;
    await Future.delayed(Duration(seconds: secondsToWait));
  }
});

final todayVerseProvider = FutureProvider<IslamicContent?>((ref) async {
  final repo = ref.read(islamicRepositoryProvider);
  final cache = ref.read(offlineCacheProvider);
  try {
    final verse = await repo.fetchTodayVerse();
    if (verse != null) {
      await cache.saveVerse({
        'id': verse.id,
        'content_type': verse.contentType,
        'title': verse.title,
        'body': verse.body,
        'source': verse.source,
        'translation_peul': verse.translationPeul,
      });
    }
    return verse;
  } catch (_) {
    final cached = cache.loadVerse();
    if (cached != null) return IslamicContent.fromJson(cached);
    rethrow;
  }
});

final homeNextEventProvider = FutureProvider<AeemgEvent?>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  final cache = ref.read(offlineCacheProvider);
  try {
    final event = await repo.fetchNextEvent();
    if (event != null) {
      await cache.saveNextEvent({
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'event_type': event.eventType,
        'location': event.location,
        'starts_at': event.startsAt.toIso8601String(),
        'ends_at': event.endsAt?.toIso8601String(),
        'is_recurring': event.isRecurring,
        'created_at': event.createdAt.toIso8601String(),
      });
    }
    return event;
  } catch (_) {
    final cached = cache.loadNextEvent();
    if (cached != null) return AeemgEvent.fromJson(cached);
    rethrow;
  }
});

final homeAnnouncementsProvider = FutureProvider((ref) async {
  final cache = ref.read(offlineCacheProvider);
  try {
    final announcements = await ref.watch(announcementsProvider.future);
    await cache.saveAnnouncements(
      announcements.map((a) => a.toJson()).toList(),
    );
    return announcements.take(3).toList();
  } catch (_) {
    final cached = cache.loadAnnouncements();
    if (cached.isEmpty) rethrow;
    return cached
        .map((e) => Announcement.fromJson(e))
        .take(3)
        .toList();
  }
});

