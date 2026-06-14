import 'package:aeemg/features/notifications/data/notification_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences', () {
    test('valeurs par défaut activées', () {
      const prefs = NotificationPreferences.defaults;
      expect(prefs.eventsEnabled, isTrue);
      expect(prefs.financeEnabled, isTrue);
    });

    test('copyWith modifie une catégorie', () {
      const prefs = NotificationPreferences.defaults;
      final updated = prefs.copyWith(eventsEnabled: false);
      expect(updated.eventsEnabled, isFalse);
      expect(updated.messagesEnabled, isTrue);
    });

    test('fromJson et toJson sont cohérents', () {
      const prefs = NotificationPreferences(
        eventsEnabled: false,
        financeEnabled: true,
        messagesEnabled: false,
        islamicEnabled: true,
        generalEnabled: true,
        smsFallbackEnabled: true,
      );
      final json = prefs.toJson();
      final restored = NotificationPreferences.fromJson(json);
      expect(restored.eventsEnabled, isFalse);
      expect(restored.messagesEnabled, isFalse);
      expect(restored.smsFallbackEnabled, isTrue);
    });
  });
}
