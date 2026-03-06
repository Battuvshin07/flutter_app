import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for `persons/{personId}`.
class PersonModel {
  final String? id;
  final String name;
  final int? birthYear;
  final int? deathYear;
  final String shortBio;
  final String? avatarUrl;
  final String? title;
  final String? fatherId;
  final String? motherId;
  final List<String> tags;
  final DateTime? updatedAt;
  final String? updatedBy;

  PersonModel({
    this.id,
    required this.name,
    this.birthYear,
    this.deathYear,
    required this.shortBio,
    this.avatarUrl,
    this.title,
    this.fatherId,
    this.motherId,
    this.tags = const [],
    this.updatedAt,
    this.updatedBy,
  });

  factory PersonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonModel(
      id: doc.id,
      name: data['name'] ?? '',
      birthYear: data['birthYear'],
      deathYear: data['deathYear'],
      shortBio: data['shortBio'] ?? '',
      avatarUrl: data['avatarUrl'],
      title: data['title'],
      fatherId: data['fatherId'],
      motherId: data['motherId'],
      tags: List<String>.from(data['tags'] ?? []),
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
      'name': name,
      'birthYear': birthYear,
      'deathYear': deathYear,
      'shortBio': shortBio,
      'avatarUrl': avatarUrl,
      'title': title,
      'fatherId': fatherId,
      'motherId': motherId,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  PersonModel copyWith({
    String? id,
    String? name,
    int? birthYear,
    int? deathYear,
    String? shortBio,
    String? avatarUrl,
    String? title,
    String? fatherId,
    String? motherId,
    List<String>? tags,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthYear: birthYear ?? this.birthYear,
      deathYear: deathYear ?? this.deathYear,
      shortBio: shortBio ?? this.shortBio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      fatherId: fatherId ?? this.fatherId,
      motherId: motherId ?? this.motherId,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
