class Event {
  final int? eventId;
  final String title;
  final String date;
  final String description;
  final int? personId;

  Event({
    this.eventId,
    required this.title,
    required this.date,
    required this.description,
    this.personId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'title': title,
      'date': date,
      'description': description,
      'person_id': personId,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      eventId: map['event_id'] as int?,
      title: map['title'] as String,
      date: map['date'] as String,
      description: map['description'] as String,
      personId: map['person_id'] as int?,
    );
  }

  Event copyWith({
    int? eventId,
    String? title,
    String? date,
    String? description,
    int? personId,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      personId: personId ?? this.personId,
    );
  }
}
