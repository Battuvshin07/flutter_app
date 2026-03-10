import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/journey_provider.dart';
import '../screens/story_detail_screen.dart';

/// Home screen card that shows the user's current quiz in the History Journey.
/// Tapping opens the StoryDetailScreen where the user can start the quiz.
class QuizJourneyCard extends StatelessWidget {
  const QuizJourneyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, journey, _) {
        // Don't render while loading or if no stories
        if (journey.isLoading) {
          return _buildSkeleton(context);
        }
        if (journey.stories.isEmpty) return const SizedBox.shrink();

        final story = journey.currentStory;
        if (story == null) return const SizedBox.shrink();

        final isCompleted = journey.isStoryCompleted(story.id);
        final hasQuiz = story.quizId != null && story.quizId!.isNotEmpty;
        final completedCount = journey.completedCount;
        final totalCount = journey.stories.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Одоогийн хичээл', style: AppTheme.sectionTitle),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$completedCount/$totalCount гүйцэтгэсэн',
                      style: AppTheme.chip.copyWith(
                        color: AppTheme.accentGold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryDetailScreen(story: story),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2E2040),
                        const Color(0xFF1A1230),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.08),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: hasQuiz
                              ? const Color(0xFFA78BFA).withValues(alpha: 0.15)
                              : AppTheme.accentGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasQuiz
                                ? const Color(0xFFA78BFA).withValues(alpha: 0.3)
                                : AppTheme.accentGold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          hasQuiz
                              ? Icons.quiz_rounded
                              : Icons.menu_book_rounded,
                          color: hasQuiz
                              ? const Color(0xFFA78BFA)
                              : AppTheme.accentGold,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title,
                              style: AppTheme.captionBold.copyWith(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (hasQuiz)
                                  _chip(
                                    Icons.quiz_outlined,
                                    'Шалгалт байна',
                                    const Color(0xFFA78BFA),
                                  ),
                                _chip(
                                  Icons.stars_rounded,
                                  '+${story.xpReward} XP',
                                  AppTheme.accentGold,
                                ),
                                if (isCompleted)
                                  _chip(
                                    Icons.check_circle_rounded,
                                    'Дууссан',
                                    const Color(0xFF4ADE80),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.accentGold,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTheme.chip.copyWith(color: color, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Одоогийн хичээл', style: AppTheme.sectionTitle),
          const SizedBox(height: 10),
          Container(
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
          ),
        ],
      ),
    );
  }
}
