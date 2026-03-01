import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';
import '../providers/journey_provider.dart';
import '../providers/story_quiz_provider.dart';
import '../components/glass_card.dart';
import '../components/gold_badge.dart';
import '../components/neon_progress_bar.dart';
import '../components/quiz_answer_button.dart';

/// Quiz screen specific to a story in the History Journey.
/// User must score ≥70 % to pass, unlock the next story and earn XP.
class StoryQuizScreen extends StatefulWidget {
  final Story story;

  const StoryQuizScreen({super.key, required this.story});

  @override
  State<StoryQuizScreen> createState() => _StoryQuizScreenState();
}

class _StoryQuizScreenState extends State<StoryQuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimCtrl;
  late Animation<double> _scorePulse;
  bool _submitting = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryQuizProvider>(context, listen: false)
          .loadQuiz(widget.story.id);
    });
  }

  @override
  void dispose() {
    _scoreAnimCtrl.dispose();
    super.dispose();
  }

  void _selectAnswer(StoryQuizProvider provider, int index) {
    provider.selectAnswer(index);
    if (index == provider.currentQuestion?.correctIndex) {
      _scoreAnimCtrl.forward(from: 0);
    }
  }

  void _next(StoryQuizProvider provider) {
    provider.nextQuestion();
    if (provider.quizFinished) {
      _submitResult(provider);
    }
  }

  Future<void> _submitResult(StoryQuizProvider provider) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final journey = Provider.of<JourneyProvider>(context, listen: false);
    await journey.submitQuizResult(
      storyId: widget.story.id,
      score: provider.score,
      total: provider.totalQuestions,
    );
    setState(() => _submitting = false);
  }

  void _retry(StoryQuizProvider provider) {
    provider.retry();
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
          child: Consumer<StoryQuizProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildAppBar(provider),
                  Expanded(
                    child: provider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.accentGold))
                        : provider.error != null
                            ? _buildError(provider.error!)
                            : provider.quizFinished
                                ? _buildResultScreen(provider)
                                : _buildQuizContent(provider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────
  Widget _buildAppBar(StoryQuizProvider provider) {
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
                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Шалгалт', style: AppTheme.h2.copyWith(fontSize: 19)),
          ),
          ScaleTransition(
            scale: _scorePulse,
            child: GoldBadge.xp(provider.score * 10),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.crimson, size: 48),
            const SizedBox(height: 16),
            Text(message, style: AppTheme.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: BorderSide(
                    color: AppTheme.cardBorder.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: const Text('Буцах'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quiz content ─────────────────────────────────────────────────
  Widget _buildQuizContent(StoryQuizProvider provider) {
    final q = provider.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final progress = (provider.currentIndex + 1) / provider.totalQuestions;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 12),
      child: Column(
        children: [
          // Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Асуулт ${provider.currentIndex + 1}/${provider.totalQuestions}',
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
                    color: AppTheme.accentGold.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.quiz_outlined,
                      color: AppTheme.accentGold, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  q.question,
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
            q.options.length,
            (index) => QuizAnswerButton(
              text: q.options[index],
              index: index,
              isSelected: provider.selectedAnswer == index,
              isRevealed: provider.answered,
              isCorrect: index == q.correctIndex,
              onTap: () => _selectAnswer(provider, index),
            ),
          ),
          const SizedBox(height: 16),

          // Next button
          if (provider.answered) _buildNextButton(provider),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Next button ──────────────────────────────────────────────────
  Widget _buildNextButton(StoryQuizProvider provider) {
    final isLast = provider.currentIndex == provider.totalQuestions - 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _next(provider),
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
  Widget _buildResultScreen(StoryQuizProvider provider) {
    final percentage = (provider.percentage * 100).toInt();
    final passed = provider.passed;

    final Color accentColor;
    final IconData trophyIcon;
    final String resultText;
    final String subText;

    if (passed && percentage >= 80) {
      accentColor = AppTheme.accentGold;
      trophyIcon = Icons.emoji_events_rounded;
      resultText = 'Маш сайн!';
      subText = 'Дараагийн түүх нээгдлээ!';
    } else if (passed) {
      accentColor = const Color(0xFF5ED8B5);
      trophyIcon = Icons.check_circle_rounded;
      resultText = 'Тэнцлээ!';
      subText = 'Дараагийн түүх нээгдлээ!';
    } else {
      accentColor = AppTheme.crimson;
      trophyIcon = Icons.menu_book_rounded;
      resultText = 'Тэнцээгүй';
      subText = '70%-аас дээш оноо авна уу';
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Trophy / icon with glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(trophyIcon, color: accentColor, size: 52),
          ),
          const SizedBox(height: 20),
          Text(resultText, style: AppTheme.h2.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text(subText, style: AppTheme.body.copyWith(color: accentColor)),
          const SizedBox(height: 12),
          Text(
            '${provider.score} / ${provider.totalQuestions} зөв хариулт',
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

          // XP badge (only meaningful when passed)
          if (passed) GoldBadge.xp(widget.story.xpReward),

          if (_submitting) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppTheme.accentGold),
          ],

          const SizedBox(height: 36),

          // Retry button (always visible)
          if (!passed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _retry(provider),
                icon: const Icon(Icons.replay_rounded),
                label: Text('Дахин оролдох', style: AppTheme.button),
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

          if (passed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pop both quiz and detail screen back to journey
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('Үргэлжлүүлэх', style: AppTheme.button),
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: AppTheme.cardBorder.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Text('Буцах',
                  style: AppTheme.button.copyWith(color: AppTheme.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
