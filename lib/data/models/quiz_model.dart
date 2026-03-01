import 'package:cloud_firestore/cloud_firestore.dart';

/// A single question within a quiz.
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };
}

/// Firestore model for `quizzes/{quizId}`.
class QuizModel {
  final String? id;
  final String title;
  final String description;
  final String difficulty; // "easy" | "medium" | "hard"
  final String topic;
  final bool isPublished;
  final List<QuizQuestion> questions;
  final DateTime? updatedAt;
  final String? updatedBy;

  QuizModel({
    this.id,
    required this.title,
    required this.description,
    this.difficulty = 'easy',
    this.topic = '',
    this.isPublished = false,
    this.questions = const [],
    this.updatedAt,
    this.updatedBy,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'easy',
      topic: data['topic'] ?? '',
      isPublished: data['isPublished'] ?? false,
      questions: (data['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'topic': topic,
      'isPublished': isPublished,
      'questions': questions.map((q) => q.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? difficulty,
    String? topic,
    bool? isPublished,
    List<QuizQuestion>? questions,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      topic: topic ?? this.topic,
      isPublished: isPublished ?? this.isPublished,
      questions: questions ?? this.questions,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
