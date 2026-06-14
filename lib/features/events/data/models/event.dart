class AeemgEvent {
  const AeemgEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    this.location,
    required this.startsAt,
    this.endsAt,
    required this.isRecurring,
    required this.createdAt,
    this.rsvpCount = 0,
    this.myRsvpStatus,
  });

  final String id;
  final String title;
  final String? description;
  final String eventType;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isRecurring;
  final DateTime createdAt;
  final int rsvpCount;
  final String? myRsvpStatus;

  factory AeemgEvent.fromJson(Map<String, dynamic> json) => AeemgEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        eventType: json['event_type'] as String? ?? 'other',
        location: json['location'] as String?,
        startsAt: DateTime.parse(json['starts_at'] as String),
        endsAt: json['ends_at'] != null
            ? DateTime.parse(json['ends_at'] as String)
            : null,
        isRecurring: json['is_recurring'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        rsvpCount: json['rsvp_count'] as int? ?? 0,
        myRsvpStatus: json['my_rsvp_status'] as String?,
      );

  String get typeLabel => switch (eventType) {
        'conference' => 'Conférence',
        'quran_contest' => 'Concours Coran',
        'outing' => 'Sortie',
        'iftar' => 'Iftar',
        'halaqa' => 'Halaqa',
        'training' => 'Formation',
        _ => 'Autre',
      };
}
