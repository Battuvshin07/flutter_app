import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for `contents/{contentId}`.
class ContentModel {
  final String? id;
  final String title;
  final String type; // e.g. "article", "video", "gallery"
  final String body;
  final String? coverImageUrl;
  final bool isPublished;
  final int order;
  final DateTime? updatedAt;
  final String? updatedBy;

  ContentModel({
    this.id,
    required this.title,
    this.type = 'article',
    this.body = '',
    this.coverImageUrl,
    this.isPublished = false,
    this.order = 0,
    this.updatedAt,
    this.updatedBy,
  });

  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'article',
      body: data['body'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      isPublished: data['isPublished'] ?? false,
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
      'type': type,
      'body': body,
      'coverImageUrl': coverImageUrl,
      'isPublished': isPublished,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  ContentModel copyWith({
    String? id,
    String? title,
    String? type,
    String? body,
    String? coverImageUrl,
    bool? isPublished,
    int? order,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      body: body ?? this.body,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublished: isPublished ?? this.isPublished,
      order: order ?? this.order,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
