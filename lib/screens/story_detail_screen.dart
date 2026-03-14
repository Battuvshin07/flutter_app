import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';
import '../providers/journey_provider.dart';
import 'story_quiz_screen.dart';

/// Displays a story's full content. User must press "Судалж дуусгах"
/// to mark studied, then "Шалгалт өгөх" becomes enabled.
class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  bool _marking = false;

  Future<void> _markStudied() async {
    setState(() => _marking = true);
    final journey = Provider.of<JourneyProvider>(context, listen: false);
    await journey.markStudied(widget.story.id);
    setState(() => _marking = false);
  }

  void _openQuiz({bool isReview = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StoryQuizScreen(story: widget.story, isReview: isReview),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1628),
              AppTheme.background,
              Color(0xFF0A0F1C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Story image
                      if (widget.story.imageUrl != null &&
                          widget.story.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          child: Image.network(
                            widget.story.imageUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      if (widget.story.imageUrl != null &&
                          widget.story.imageUrl!.isNotEmpty)
                        const SizedBox(height: 20),

                      // Title
                      Text(widget.story.title,
                          style: AppTheme.h2.copyWith(fontSize: 22)),
                      const SizedBox(height: 8),

                      // XP badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_outlined,
                                size: 14, color: AppTheme.accentGold),
                            const SizedBox(width: 4),
                            Text(
                              '+${widget.story.xpReward} XP',
                              style: AppTheme.chip
                                  .copyWith(color: AppTheme.accentGold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Content
                      Text(
                        widget.story.content,
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                    color: AppTheme.accentGold.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Text('Түүх судлах', style: AppTheme.h2.copyWith(fontSize: 19)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<JourneyProvider>(
      builder: (context, journey, _) {
        final studied = journey.isStoryStudied(widget.story.id);
        final quizPassed = journey.isStoryCompleted(widget.story.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Study button
            if (!studied)
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _marking ? null : _markStudied,
                  icon: _marking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.background),
                        )
                      : const Icon(Icons.menu_book_rounded),
                  label: Text('Судалж дуусгах',
                      style: AppTheme.button.copyWith(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5ED8B5),
                    foregroundColor: AppTheme.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),

            if (studied && !quizPassed) ...[
              // Studied badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4ADE80), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Судалж дууссан',
                      style: AppTheme.captionBold
                          .copyWith(color: const Color(0xFF4ADE80)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quiz button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _openQuiz(),
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text('Шалгалт өгөх',
                      style: AppTheme.button.copyWith(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
            ],

            if (quizPassed) ...[
              // Completed badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: AppTheme.accentGold, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Амжилттай дуусгасан!',
                      style: AppTheme.captionBold
                          .copyWith(color: AppTheme.accentGold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Retry quiz button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _openQuiz(isReview: true),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text('Дахин судлах',
                      style: AppTheme.button.copyWith(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
