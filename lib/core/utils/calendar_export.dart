import '../../features/events/data/models/event.dart';

/// Lien Google Calendar pour un événement AEEMG.
String googleCalendarUrl(AeemgEvent event) {
  String fmt(DateTime dt) =>
      '${dt.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';

  final start = fmt(event.startsAt);
  final end = fmt(
    event.endsAt ?? event.startsAt.add(const Duration(hours: 2)),
  );
  final title = Uri.encodeComponent(event.title);
  final details = Uri.encodeComponent(event.description ?? 'Événement AEEMG');
  final location = Uri.encodeComponent(event.location ?? '');

  return 'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=$title&dates=$start/$end&details=$details&location=$location';
}
