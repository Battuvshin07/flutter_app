import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/quiz.dart';

/// FR-04: Мэдлэг шалгах quiz, оноо цуглуулах
/// "Асуулт хариулт, оноо харуулах, дахин тоглох"
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _brown = Color(0xFF3B2F2F);
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);
  static const _cardBg = Color(0xFFFFFBF5);

  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _quizComplete = false;
  List<Quiz> _shuffledQuizzes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initQuiz();
    });
  }

  void _initQuiz() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _shuffledQuizzes = List<Quiz>.from(provider.quizzes)..shuffle();
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _quizComplete = false;
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _shuffledQuizzes[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _shuffledQuizzes.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() {
        _quizComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_parchment, _parchmentDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _shuffledQuizzes.isEmpty
                    ? const Center(child: Text('Quiz олдсонгүй'))
                    : _quizComplete
                        ? _buildResultScreen()
                        : _buildQuizContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child:
                const Icon(Icons.arrow_back_ios_new, color: _brown, size: 24),
          ),
          const Expanded(
            child: Text(
              'Мэдлэг шалгах',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _brown,
              ),
            ),
          ),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6B8E23).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFB8860B)),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B8E23),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    final quiz = _shuffledQuizzes[_currentQuestionIndex];
    final List<dynamic> answers = json.decode(quiz.answers);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: 24),
          // Question card
          _buildQuestionCard(quiz),
          const SizedBox(height: 20),
          // Answer options
          ...List.generate(
            answers.length,
            (index) => _buildAnswerOption(
              answers[index].toString(),
              index,
              quiz.correctAnswer,
            ),
          ),
          const SizedBox(height: 24),
          // Next button
          if (_answered) _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / _shuffledQuizzes.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Асуулт ${_currentQuestionIndex + 1}/${_shuffledQuizzes.length}',
              style: TextStyle(
                fontSize: 13,
                color: _brown.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 13,
                color: _brown.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: _brown.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Quiz quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child:
                  Icon(Icons.quiz_outlined, color: Color(0xFF8B4513), size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            quiz.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _brown,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String answer, int index, int correctIndex) {
    Color bgColor = _cardBg;
    Color borderColor = Colors.grey.shade300;
    Color textColor = _brown;
    IconData? trailingIcon;

    if (_answered) {
      if (index == correctIndex) {
        bgColor = const Color(0xFF6B8E23).withOpacity(0.1);
        borderColor = const Color(0xFF6B8E23);
        textColor = const Color(0xFF6B8E23);
        trailingIcon = Icons.check_circle;
      } else if (index == _selectedAnswer && index != correctIndex) {
        bgColor = const Color(0xFF8B0000).withOpacity(0.1);
        borderColor = const Color(0xFF8B0000);
        textColor = const Color(0xFF8B0000);
        trailingIcon = Icons.cancel;
      }
    } else if (_selectedAnswer == index) {
      borderColor = const Color(0xFF8B4513);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderColor.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentQuestionIndex == _shuffledQuizzes.length - 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          isLast ? 'Үр дүн харах' : 'Дараагийн асуулт',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final total = _shuffledQuizzes.length;
    final percentage = (_score / total * 100).toInt();
    final emoji = percentage >= 80
        ? '🏆'
        : percentage >= 50
            ? '👍'
            : '📚';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            percentage >= 80
                ? 'Маш сайн!'
                : percentage >= 50
                    ? 'Сайн байна!'
                    : 'Дахин оролдоорой!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_score / $total зөв хариулт',
            style: TextStyle(
              fontSize: 18,
              color: _brown.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: percentage >= 80
                  ? const Color(0xFF6B8E23)
                  : percentage >= 50
                      ? const Color(0xFFB8860B)
                      : const Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 30),
          // Replay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _initQuiz,
              icon: const Icon(Icons.replay),
              label: const Text(
                'Дахин тоглох',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Back to home
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brown,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: _brown.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Нүүр хуудас',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
