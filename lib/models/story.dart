import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for stories/{storyId}.
class Story {
  final String id;
  final String title;
  final String content;
  final int order;
  final int xpReward;
  final String? quizId;
  final String? imageUrl;

  Story({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.xpReward,
    this.quizId,
    this.imageUrl,
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      title: d['title'] ?? '',
      content: d['content'] ?? '',
      order: (d['order'] ?? 0) as int,
      xpReward: (d['xpReward'] ?? 100) as int,
      quizId: d['quizId'] as String?,
      imageUrl: d['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'content': content,
        'order': order,
        'xpReward': xpReward,
        'quizId': quizId,
        'imageUrl': imageUrl,
      };
}

/// Firestore model for users/{uid}/progress/{storyId}.
class UserStoryProgress {
  final String storyId;
  final bool studied;
  final bool quizPassed;
  final int xpEarned;
  final DateTime? updatedAt;

  UserStoryProgress({
    required this.storyId,
    this.studied = false,
    this.quizPassed = false,
    this.xpEarned = 0,
    this.updatedAt,
  });

  factory UserStoryProgress.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserStoryProgress(
      storyId: doc.id,
      studied: d['studied'] == true,
      quizPassed: d['quizPassed'] == true,
      xpEarned: (d['xpEarned'] ?? 0) as int,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studied': studied,
        'quizPassed': quizPassed,
        'xpEarned': xpEarned,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  UserStoryProgress copyWith({
    bool? studied,
    bool? quizPassed,
    int? xpEarned,
  }) {
    return UserStoryProgress(
      storyId: storyId,
      studied: studied ?? this.studied,
      quizPassed: quizPassed ?? this.quizPassed,
      xpEarned: xpEarned ?? this.xpEarned,
      updatedAt: updatedAt,
    );
  }
}

/// A single quiz question within a story quiz.
class StoryQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  StoryQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory StoryQuizQuestion.fromMap(Map<String, dynamic> m) {
    return StoryQuizQuestion(
      question: m['question'] ?? '',
      options: List<String>.from(m['options'] ?? []),
      correctIndex: (m['correctIndex'] ?? 0) as int,
    );
  }
}

/// Firestore model for quizzes/{quizId} (story quiz version).
class StoryQuiz {
  final String id;
  final String storyId;
  final List<StoryQuizQuestion> questions;

  StoryQuiz({
    required this.id,
    required this.storyId,
    required this.questions,
  });

  factory StoryQuiz.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawQuestions = d['questions'] as List<dynamic>? ?? [];
    return StoryQuiz(
      id: doc.id,
      storyId: d['storyId'] ?? '',
      questions: rawQuestions
          .map((q) => StoryQuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
