import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for `cultures/{cultureId}`.
class CultureModel {
  final String? id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final int order;
  final DateTime? updatedAt;
  final String? updatedBy;

  CultureModel({
    this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
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
      order: data['order'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
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
    int? order,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return CultureModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      order: order ?? this.order,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
