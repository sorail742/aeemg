import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache local léger pour l'accueil (Phase 4 — mode hors ligne partiel).
class OfflineCache {
  OfflineCache(this._prefs);

  final SharedPreferences _prefs;

  static const _verseKey = 'cache_verse';
  static const _eventKey = 'cache_next_event';
  static const _announcementsKey = 'cache_announcements';
  static const _eventsMonthKey = 'cache_events_month';

  Future<void> saveVerse(Map<String, dynamic> json) async {
    await _prefs.setString(_verseKey, jsonEncode(json));
  }

  Map<String, dynamic>? loadVerse() {
    final raw = _prefs.getString(_verseKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveNextEvent(Map<String, dynamic> json) async {
    await _prefs.setString(_eventKey, jsonEncode(json));
  }

  Map<String, dynamic>? loadNextEvent() {
    final raw = _prefs.getString(_eventKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveAnnouncements(List<Map<String, dynamic>> items) async {
    await _prefs.setString(_announcementsKey, jsonEncode(items));
  }

  List<Map<String, dynamic>> loadAnnouncements() {
    final raw = _prefs.getString(_announcementsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveEventsMonth(String monthKey, List<Map<String, dynamic>> items) async {
    await _prefs.setString('$_eventsMonthKey$monthKey', jsonEncode(items));
  }

  List<Map<String, dynamic>> loadEventsMonth(String monthKey) {
    final raw = _prefs.getString('$_eventsMonthKey$monthKey');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> clear() async {
    await _prefs.remove(_verseKey);
    await _prefs.remove(_eventKey);
    await _prefs.remove(_announcementsKey);
  }
}
