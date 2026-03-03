import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for `stories/{storyId}`.
class StoryModel {
  final String? id;
  final String title;
  final String subtitle;
  final String content;
  final int order;
  final int xpReward;
  final String? quizId; // reference to quizzes/{quizId}
  final bool isPublished;
  final String? imageUrl;
  final DateTime? updatedAt;
  final String? updatedBy;

  StoryModel({
    this.id,
    required this.title,
    this.subtitle = '',
    this.content = '',
    required this.order,
    this.xpReward = 100,
    this.quizId,
    this.isPublished = false,
    this.imageUrl,
    this.updatedAt,
    this.updatedBy,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      content: data['content'] ?? '',
      order: data['order'] ?? 1,
      xpReward: data['xpReward'] ?? 100,
      quizId: data['quizId'],
      isPublished: data['isPublished'] ?? false,
      imageUrl: data['imageUrl'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'order': order,
      'xpReward': xpReward,
      'quizId': quizId,
      'isPublished': isPublished,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  StoryModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? content,
    int? order,
    int? xpReward,
    String? quizId,
    bool? isPublished,
    String? imageUrl,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      content: content ?? this.content,
      order: order ?? this.order,
      xpReward: xpReward ?? this.xpReward,
      quizId: quizId ?? this.quizId,
      isPublished: isPublished ?? this.isPublished,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
