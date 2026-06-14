import 'package:aeemg/core/cache/offline_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineCache', () {
    late OfflineCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cache = OfflineCache(prefs);
    });

    test('sauvegarde et charge un verset', () async {
      await cache.saveVerse({
        'id': 'v1',
        'content_type': 'verse',
        'body': 'Test',
      });
      expect(cache.loadVerse()?['body'], 'Test');
    });

    test('sauvegarde et charge un événement', () async {
      await cache.saveNextEvent({
        'id': 'e1',
        'title': 'Conférence',
        'event_type': 'conference',
        'starts_at': '2026-06-20T18:00:00.000Z',
        'is_recurring': false,
        'created_at': '2026-06-01T00:00:00.000Z',
      });
      expect(cache.loadNextEvent()?['title'], 'Conférence');
    });
  });
}
