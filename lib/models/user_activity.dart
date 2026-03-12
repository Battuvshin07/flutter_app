// ════════════════════════════════════════════════════════
//  UserFavorite – saved story bookmark
//  Subcollection: users/{uid}/favorites/{id}
// ════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class UserFavorite {
  final String id;
  final String storyId;
  final String title;
  final DateTime savedAt;

  const UserFavorite({
    required this.id,
    required this.storyId,
    required this.title,
    required this.savedAt,
  });

  factory UserFavorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserFavorite(
      id: doc.id,
      storyId: data['storyId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storyId': storyId,
        'title': title,
        'savedAt': Timestamp.fromDate(savedAt),
      };
}

// ════════════════════════════════════════════════════════
//  UserHistory – recently viewed story record
//  Subcollection: users/{uid}/history/{id}
// ════════════════════════════════════════════════════════

class UserHistory {
  final String id;
  final String storyId;
  final String title;
  final DateTime viewedAt;

  const UserHistory({
    required this.id,
    required this.storyId,
    required this.title,
    required this.viewedAt,
  });

  factory UserHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserHistory(
      id: doc.id,
      storyId: data['storyId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storyId': storyId,
        'title': title,
        'viewedAt': Timestamp.fromDate(viewedAt),
      };
}
