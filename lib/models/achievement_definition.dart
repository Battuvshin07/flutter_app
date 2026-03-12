// ════════════════════════════════════════════════════════
//  AchievementDefinition – master achievement catalog
//  Collection: achievements/{id}
//
//  Each document defines one possible achievement.
//  User-specific unlock state lives in users/{uid}/achievements/{id}.
// ════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String icon; // 'trophy' | 'shield' | 'medal' | 'star' | 'book' …
  final int expReward; // XP granted when unlocked
  final String
      conditionType; // 'stories_completed' | 'quizzes_completed' | 'xp_total' | 'streak_days' | 'cultures_completed'
  final int conditionValue; // threshold to unlock
  final int sortOrder;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.icon = 'trophy',
    this.expReward = 0,
    required this.conditionType,
    required this.conditionValue,
    this.sortOrder = 0,
  });

  factory AchievementDefinition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AchievementDefinition(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'trophy',
      expReward: (data['expReward'] as num? ?? 0).toInt(),
      conditionType: data['conditionType'] as String? ?? '',
      conditionValue: (data['conditionValue'] as num? ?? 0).toInt(),
      sortOrder: (data['sortOrder'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'icon': icon,
        'expReward': expReward,
        'conditionType': conditionType,
        'conditionValue': conditionValue,
        'sortOrder': sortOrder,
      };
}
