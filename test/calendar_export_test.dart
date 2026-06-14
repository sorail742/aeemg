import 'package:aeemg/core/utils/calendar_export.dart';
import 'package:aeemg/features/events/data/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('googleCalendarUrl contient titre et dates', () {
    final event = AeemgEvent(
      id: '1',
      title: 'Conference AEEMG',
      eventType: 'conference',
      location: 'Conakry',
      startsAt: DateTime.utc(2026, 6, 20, 18),
      isRecurring: false,
      createdAt: DateTime.utc(2026, 6, 1),
    );
    final url = googleCalendarUrl(event);
    expect(url, contains('calendar.google.com'));
    expect(url, contains('Conference'));
  });
}
