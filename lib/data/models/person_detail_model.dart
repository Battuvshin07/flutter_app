import 'package:cloud_firestore/cloud_firestore.dart';

/// Timeline entry for person detail.
class TimelineEntry {
  final int year;
  final String text;

  TimelineEntry({required this.year, required this.text});

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
    return TimelineEntry(
      year: map['year'] ?? 0,
      text: map['text'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'year': year, 'text': text};
}

/// Source reference for person detail.
class SourceRef {
  final String title;
  final String url;

  SourceRef({required this.title, required this.url});

  factory SourceRef.fromMap(Map<String, dynamic> map) {
    return SourceRef(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'title': title, 'url': url};
}

/// Firestore model for `person_details/{personId}` (1:1 with persons).
class PersonDetailModel {
  final String? id; // same as personId
  final String longBio;
  final List<String> achievements;
  final List<TimelineEntry> timeline;
  final List<SourceRef> sources;
  final DateTime? updatedAt;
  final String? updatedBy;

  PersonDetailModel({
    this.id,
    required this.longBio,
    this.achievements = const [],
    this.timeline = const [],
    this.sources = const [],
    this.updatedAt,
    this.updatedBy,
  });

  factory PersonDetailModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonDetailModel(
      id: doc.id,
      longBio: data['longBio'] ?? '',
      achievements: List<String>.from(data['achievements'] ?? []),
      timeline: (data['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      sources: (data['sources'] as List<dynamic>?)
              ?.map((e) => SourceRef.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: _parseTimestamp(data['updatedAt']),
      updatedBy: data['updatedBy'],
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'longBio': longBio,
      'achievements': achievements,
      'timeline': timeline.map((e) => e.toMap()).toList(),
      'sources': sources.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  PersonDetailModel copyWith({
    String? id,
    String? longBio,
    List<String>? achievements,
    List<TimelineEntry>? timeline,
    List<SourceRef>? sources,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PersonDetailModel(
      id: id ?? this.id,
      longBio: longBio ?? this.longBio,
      achievements: achievements ?? this.achievements,
      timeline: timeline ?? this.timeline,
      sources: sources ?? this.sources,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
