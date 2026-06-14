import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.eventsEnabled,
    required this.financeEnabled,
    required this.messagesEnabled,
    required this.islamicEnabled,
    required this.generalEnabled,
    this.smsFallbackEnabled = false,
  });

  final bool eventsEnabled;
  final bool financeEnabled;
  final bool messagesEnabled;
  final bool islamicEnabled;
  final bool generalEnabled;
  final bool smsFallbackEnabled;

  static const defaults = NotificationPreferences(
    eventsEnabled: true,
    financeEnabled: true,
    messagesEnabled: true,
    islamicEnabled: true,
    generalEnabled: true,
  );

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        eventsEnabled: json['events_enabled'] as bool? ?? true,
        financeEnabled: json['finance_enabled'] as bool? ?? true,
        messagesEnabled: json['messages_enabled'] as bool? ?? true,
        islamicEnabled: json['islamic_enabled'] as bool? ?? true,
        generalEnabled: json['general_enabled'] as bool? ?? true,
        smsFallbackEnabled: json['sms_fallback_enabled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'events_enabled': eventsEnabled,
        'finance_enabled': financeEnabled,
        'messages_enabled': messagesEnabled,
        'islamic_enabled': islamicEnabled,
        'general_enabled': generalEnabled,
        'sms_fallback_enabled': smsFallbackEnabled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  NotificationPreferences copyWith({
    bool? eventsEnabled,
    bool? financeEnabled,
    bool? messagesEnabled,
    bool? islamicEnabled,
    bool? generalEnabled,
    bool? smsFallbackEnabled,
  }) =>
      NotificationPreferences(
        eventsEnabled: eventsEnabled ?? this.eventsEnabled,
        financeEnabled: financeEnabled ?? this.financeEnabled,
        messagesEnabled: messagesEnabled ?? this.messagesEnabled,
        islamicEnabled: islamicEnabled ?? this.islamicEnabled,
        generalEnabled: generalEnabled ?? this.generalEnabled,
        smsFallbackEnabled: smsFallbackEnabled ?? this.smsFallbackEnabled,
      );
}

class NotificationPreferencesRepository {
  NotificationPreferencesRepository(this._client);

  final SupabaseClient? _client;

  Future<NotificationPreferences> fetch(String userId) async {
    final row = await _client
        ?.from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return NotificationPreferences.defaults;
    return NotificationPreferences.fromJson(row);
  }

  Future<void> upsert(String userId, NotificationPreferences prefs) async {
    await _client?.from('notification_preferences').upsert({
      'user_id': userId,
      ...prefs.toJson(),
    });
  }
}
