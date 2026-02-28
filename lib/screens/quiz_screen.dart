import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/gold_badge.dart';
import '../components/neon_progress_bar.dart';
import '../components/quiz_answer_button.dart';

/// FR-04: Мэдлэг шалгах quiz, оноо цуглуулах
/// Dark + gold gamified quiz experience
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _quizComplete = false;
  List<Quiz> _shuffledQuizzes = [];

  late AnimationController _scoreAnimCtrl;
  late Animation<double> _scorePulse;

  @override
  void initState() {
    super.initState();
    _scoreAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scorePulse = Tween(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _scoreAnimCtrl, curve: Curves.elasticOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initQuiz());
  }

  @override
  void dispose() {
    _scoreAnimCtrl.dispose();
    super.dispose();
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
        _scoreAnimCtrl.forward(from: 0);
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
      setState(() => _quizComplete = true);
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
            colors: [
              AppTheme.background,
              Color(0xFF0F1A2E),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _shuffledQuizzes.isEmpty
                    ? Center(
                        child: Text('Quiz олдсонгүй', style: AppTheme.body),
                      )
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

  // ── App bar ──────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.35),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Мэдлэг шалгах',
                style: AppTheme.h2.copyWith(fontSize: 19)),
          ),
          // Animated score badge
          ScaleTransition(
            scale: _scorePulse,
            child: GoldBadge.xp(_score * 10),
          ),
        ],
      ),
    );
  }

  // ── Quiz content ─────────────────────────────────────────────────
  Widget _buildQuizContent() {
    final quiz = _shuffledQuizzes[_currentQuestionIndex];
    final List<dynamic> answers = json.decode(quiz.answers);
    final progress = (_currentQuestionIndex + 1) / _shuffledQuizzes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 12),
      child: Column(
        children: [
          // Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Асуулт ${_currentQuestionIndex + 1}/${_shuffledQuizzes.length}',
                style: AppTheme.caption,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTheme.captionBold.copyWith(
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NeonProgressBar(progress: progress),
          const SizedBox(height: 24),

          // Question card
          GlassCard(
            glowColor: AppTheme.accentGold,
            glowIntensity: 0.08,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentGold.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.quiz_outlined,
                      color: AppTheme.accentGold, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  quiz.question,
                  textAlign: TextAlign.center,
                  style: AppTheme.sectionTitle.copyWith(
                    fontSize: 17,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Answer options
          ...List.generate(
            answers.length,
            (index) => QuizAnswerButton(
              text: answers[index].toString(),
              index: index,
              isSelected: _selectedAnswer == index,
              isRevealed: _answered,
              isCorrect: index == quiz.correctAnswer,
              onTap: () => _selectAnswer(index),
            ),
          ),
          const SizedBox(height: 16),

          // Next / Result button
          if (_answered) _buildNextButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Next button ──────────────────────────────────────────────────
  Widget _buildNextButton() {
    final isLast = _currentQuestionIndex == _shuffledQuizzes.length - 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          elevation: 0,
        ),
        child: Text(
          isLast ? 'Үр дүн харах' : 'Дараагийн асуулт',
          style: AppTheme.button,
        ),
      ),
    );
  }

  // ── Result screen ────────────────────────────────────────────────
  Widget _buildResultScreen() {
    final total = _shuffledQuizzes.length;
    final percentage = (_score / total * 100).toInt();

    final Color accentColor;
    final IconData trophyIcon;
    final String resultText;
    if (percentage >= 80) {
      accentColor = AppTheme.accentGold;
      trophyIcon = Icons.emoji_events_rounded;
      resultText = 'Маш сайн!';
    } else if (percentage >= 50) {
      accentColor = AppTheme.streakOrange;
      trophyIcon = Icons.thumb_up_alt_rounded;
      resultText = 'Сайн байна!';
    } else {
      accentColor = AppTheme.crimson;
      trophyIcon = Icons.menu_book_rounded;
      resultText = 'Дахин оролдоорой!';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Trophy icon with glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(trophyIcon, color: accentColor, size: 52),
          ),
          const SizedBox(height: 20),
          Text(resultText, style: AppTheme.h2.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Text(
            '$_score / $total зөв хариулт',
            style: AppTheme.body.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Percentage
          Text(
            '$percentage%',
            style: AppTheme.h2.copyWith(
              fontSize: 56,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          // XP earned
          GoldBadge.xp(_score * 10),
          const SizedBox(height: 36),

          // Replay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _initQuiz,
              icon: const Icon(Icons.replay_rounded),
              label: Text('Дахин тоглох', style: AppTheme.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Home button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppTheme.cardBorder.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Text('Нүүр хуудас',
                  style: AppTheme.button.copyWith(color: AppTheme.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
