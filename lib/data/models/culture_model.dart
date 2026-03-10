import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for `cultures/{cultureId}`.
class CultureModel {
  final String? id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String? icon;
  final String? details;
  final int order;
  final DateTime? updatedAt;
  final String? updatedBy;

  CultureModel({
    this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    this.icon,
    this.details,
    this.order = 0,
    this.updatedAt,
    this.updatedBy,
  });

  factory CultureModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CultureModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      icon: data['icon'],
      details: data['details'],
      order: data['order'] ?? 0,
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
      'description': description,
      'coverImageUrl': coverImageUrl,
      'icon': icon,
      'details': details,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  CultureModel copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    String? icon,
    String? details,
    int? order,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return CultureModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      icon: icon ?? this.icon,
      details: details ?? this.details,
      order: order ?? this.order,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
