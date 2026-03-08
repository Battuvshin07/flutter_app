import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/quiz_model.dart';
import '../models/story.dart';

/// Loads and manages a quiz for a specific story.
/// Quiz data is sourced from the admin-managed `quizzes` Firestore collection.
class StoryQuizProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StoryQuiz? _quiz;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _quizFinished = false;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────
  StoryQuiz? get quiz => _quiz;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int? get selectedAnswer => _selectedAnswer;
  bool get answered => _answered;
  bool get quizFinished => _quizFinished;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalQuestions => _quiz?.questions.length ?? 0;
  StoryQuizQuestion? get currentQuestion =>
      _quiz != null && _currentIndex < _quiz!.questions.length
          ? _quiz!.questions[_currentIndex]
          : null;

  double get percentage => totalQuestions > 0 ? _score / totalQuestions : 0.0;
  bool get passed => percentage >= 0.7;

  // ── Load quiz by quizId from admin quizzes collection ────────
  Future<void> loadQuiz(String? quizId) async {
    if (quizId == null || quizId.isEmpty) {
      _isLoading = false;
      _error = 'Энэ түүхэд шалгалт байхгүй байна';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _quiz = null;
    _reset();
    notifyListeners();

    try {
      final doc = await _db.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        final model = QuizModel.fromFirestore(doc);
        _quiz = StoryQuiz(
          id: model.id ?? quizId,
          storyId: quizId,
          title: model.title,
          difficulty: model.difficulty,
          questions: model.questions
              .map((q) => StoryQuizQuestion(
                    question: q.question,
                    options: q.options,
                    correctIndex: q.correctIndex,
                  ))
              .toList(),
        );
      } else {
        _error = 'Шалгалт олдсонгүй';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('StoryQuizProvider.loadQuiz error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Answer selection ─────────────────────────────────────────
  void selectAnswer(int index) {
    if (_answered || _quiz == null) return;
    _selectedAnswer = index;
    _answered = true;
    if (index == currentQuestion?.correctIndex) _score++;
    notifyListeners();
  }

  // ── Next question ────────────────────────────────────────────
  void nextQuestion() {
    if (_currentIndex < totalQuestions - 1) {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
    } else {
      _quizFinished = true;
    }
    notifyListeners();
  }

  // ── Reset for retry ──────────────────────────────────────────
  void retry() {
    _reset();
    // Shuffle questions for variety
    _quiz?.questions.shuffle();
    notifyListeners();
  }

  void _reset() {
    _currentIndex = 0;
    _score = 0;
    _selectedAnswer = null;
    _answered = false;
    _quizFinished = false;
  }
}
