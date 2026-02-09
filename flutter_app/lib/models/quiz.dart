class Quiz {
  final int? quizId;
  final String question;
  final String answers; // JSON формат: ["Хариулт 1", "Хариулт 2", "Хариулт 3", "Хариулт 4"]
  final int correctAnswer; // 0-3 index

  Quiz({
    this.quizId,
    required this.question,
    required this.answers,
    required this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'quiz_id': quizId,
      'question': question,
      'answers': answers,
      'correct_answer': correctAnswer,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      quizId: map['quiz_id'] as int?,
      question: map['question'] as String,
      answers: map['answers'] as String,
      correctAnswer: map['correct_answer'] as int,
    );
  }

  Quiz copyWith({
    int? quizId,
    String? question,
    String? answers,
    int? correctAnswer,
  }) {
    return Quiz(
      quizId: quizId ?? this.quizId,
      question: question ?? this.question,
      answers: answers ?? this.answers,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }
}
