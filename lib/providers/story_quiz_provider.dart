import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story.dart';

/// Loads and manages a quiz for a specific story.
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

  // ── Load quiz for a story ────────────────────────────────────
  Future<void> loadQuiz(String storyId) async {
    _isLoading = true;
    _error = null;
    _quiz = null;
    _reset();
    notifyListeners();

    try {
      // Find quiz doc where storyId matches
      final snap = await _db
          .collection('story_quizzes')
          .where('storyId', isEqualTo: storyId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _quiz = StoryQuiz.fromFirestore(snap.docs.first);
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
