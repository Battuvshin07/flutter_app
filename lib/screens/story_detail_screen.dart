import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/story.dart';
import '../providers/journey_provider.dart';
import 'story_quiz_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  STORY DETAIL SCREEN — rich lesson view
// ══════════════════════════════════════════════════════════════════

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
    await Provider.of<JourneyProvider>(context, listen: false)
        .markStudied(widget.story.id);
    if (mounted) setState(() => _marking = false);
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
    final s = widget.story;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1628), AppTheme.background, Color(0xFF0A0F1C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    4,
                    AppTheme.pagePadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero image
                      LessonImage(story: s),
                      const SizedBox(height: 20),

                      // 2. Lesson title
                      Text(s.title, style: AppTheme.h2.copyWith(fontSize: 24)),
                      const SizedBox(height: 16),

                      // 3. Main content
                      LessonContent(content: s.content),

                      // 4. Quick facts
                      if (s.quickFacts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        QuickFactsCard(facts: s.quickFacts),
                      ],

                      // 5. Did you know
                      if (s.didYouKnow != null && s.didYouKnow!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        DidYouKnowBox(text: s.didYouKnow!),
                      ],

                      // 6. Timeline
                      if (s.timeline.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        TimelineSection(events: s.timeline),
                      ],

                      const SizedBox(height: 32),

                      // 7. Completion / quiz button
                      _buildActionButtons(),
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

        if (quizPassed) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CompletedBadge(),
              const SizedBox(height: 14),
              _PrimaryButton(
                label: 'Дахин судлах',
                icon: Icons.replay_rounded,
                color: AppTheme.accentGold,
                onTap: () => _openQuiz(isReview: true),
              ),
            ],
          );
        }

        if (studied) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _StudiedBadge(),
              const SizedBox(height: 14),
              _PrimaryButton(
                label: 'Шалгалт өгөх',
                icon: Icons.quiz_rounded,
                color: AppTheme.accentGold,
                onTap: _openQuiz,
              ),
            ],
          );
        }

        return _PrimaryButton(
          label: 'Хичээлийг дуусгах',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF5ED8B5),
          loading: _marking,
          onTap: _markStudied,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  LESSON IMAGE
// ══════════════════════════════════════════════════════════════════

class LessonImage extends StatelessWidget {
  final Story story;
  const LessonImage({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final hasImage = story.imageUrl?.isNotEmpty == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: SizedBox(
        width: double.infinity,
        height: 220,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    story.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xBB0B1220)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3050), Color(0xFF0D1628)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 72,
            color: AppTheme.accentGold.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 10),
          Text(
            'МОНГОЛЫН ТҮҮХ',
            style: TextStyle(
              color: AppTheme.accentGold.withValues(alpha: 0.45),
              fontSize: 12,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  LESSON CONTENT
// ══════════════════════════════════════════════════════════════════

class LessonContent extends StatelessWidget {
  final String content;
  const LessonContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        content,
        style: AppTheme.body.copyWith(
          fontSize: 15,
          height: 1.85,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  QUICK FACTS CARD
// ══════════════════════════════════════════════════════════════════

class QuickFactsCard extends StatelessWidget {
  final List<String> facts;
  const QuickFactsCard({super.key, required this.facts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141E30),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppTheme.accentGold, size: 17),
              ),
              const SizedBox(width: 10),
              Text('Товч баримтууд',
                  style: AppTheme.sectionTitle.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E2D45), height: 1),
          const SizedBox(height: 14),
          ...facts.map(
            (fact) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fact,
                      style: AppTheme.body.copyWith(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DID YOU KNOW BOX
// ══════════════════════════════════════════════════════════════════

class DidYouKnowBox extends StatelessWidget {
  final String text;
  const DidYouKnowBox({super.key, required this.text});

  static const _teal = Color(0xFF5ED8B5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2028),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: _teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: _teal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Та мэдэх үү?',
                  style: AppTheme.captionBold.copyWith(
                    color: _teal,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: AppTheme.body.copyWith(
                    fontSize: 14,
                    height: 1.65,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TIMELINE SECTION
// ══════════════════════════════════════════════════════════════════

class TimelineSection extends StatelessWidget {
  final List<Map<String, String>> events;
  const TimelineSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.timeline_rounded,
                  color: AppTheme.accentGold, size: 17),
            ),
            const SizedBox(width: 10),
            Text('Цаг хугацааны шугам',
                style: AppTheme.sectionTitle.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(events.length, (i) {
          final ev = events[i];
          final isLast = i == events.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical track + dot
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.background,
                          border: Border.all(
                              color: AppTheme.accentGold, width: 2.5),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 2,
                              color:
                                  AppTheme.accentGold.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Year + event text
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev['year'] ?? '',
                          style: AppTheme.captionBold.copyWith(
                            color: AppTheme.accentGold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ev['event'] ?? '',
                          style: AppTheme.body.copyWith(
                            fontSize: 14,
                            height: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.background),
              )
            : Icon(icon),
        label: Text(label, style: AppTheme.button.copyWith(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppTheme.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _StudiedBadge extends StatelessWidget {
  const _StudiedBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border:
            Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ADE80), size: 20),
          const SizedBox(width: 8),
          Text('Хичээлийг дуусгасан',
              style: AppTheme.captionBold
                  .copyWith(color: const Color(0xFF4ADE80))),
        ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
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
    );
  }
}
