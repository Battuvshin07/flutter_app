import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for `events/{eventId}`.
class EventModel {
  final String? id;
  final String title;
  final String date; // stored as string, e.g. "1206", "1227-03"
  final String description;
  final String? location;
  final String? coverImageUrl;
  final String? personId;
  final DateTime? updatedAt;
  final String? updatedBy;

  EventModel({
    this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.location,
    this.coverImageUrl,
    this.personId,
    this.updatedAt,
    this.updatedBy,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      description: data['description'] ?? '',
      location: data['location'],
      coverImageUrl: data['coverImageUrl'],
      personId: data['personId'],
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
      'title': title,
      'date': date,
      'description': description,
      'location': location,
      'coverImageUrl': coverImageUrl,
      'personId': personId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? date,
    String? description,
    String? location,
    String? coverImageUrl,
    String? personId,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      location: location ?? this.location,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      personId: personId ?? this.personId,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
