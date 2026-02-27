import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/persons_screen.dart';
import '../screens/events_timeline_screen.dart';
import '../screens/map_screen.dart';
import '../screens/quiz_screen.dart';

/// E) Explore grid 2×2 – each card 171×92, radius 18.
class ExploreGrid extends StatelessWidget {
  const ExploreGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Судлах сэдвүүд', style: AppTheme.sectionTitle),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _ExploreCard(
                  emoji: '👑',
                  title: 'Хүмүүс',
                  subtitle: '(Leaders)',
                  color: const Color(0xFF2A3A5C),
                  onTap: () => _push(context, const PersonsScreen()),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _ExploreCard(
                  emoji: '⚔️',
                  title: 'Тулаан',
                  subtitle: '(Battles)',
                  color: const Color(0xFF3B1F2B),
                  onTap: () => _push(context, const EventsTimelineScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Expanded(
                child: _ExploreCard(
                  emoji: '🗺️',
                  title: 'Газрын зураг',
                  subtitle: '(Map)',
                  color: const Color(0xFF1B3328),
                  onTap: () => _push(context, const MapScreen()),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _ExploreCard(
                  emoji: '🧠',
                  title: 'Түүхийн Quiz',
                  subtitle: '(Ranked)',
                  color: const Color(0xFF2E2040),
                  onTap: () => _push(context, const QuizScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _ExploreCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExploreCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ExploreCard> createState() => _ExploreCardState();
}

class _ExploreCardState extends State<_ExploreCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: AppTheme.captionBold.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.subtitle,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
