import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../screens/event_detail_screen.dart';
import 'glass_card.dart';
import 'gold_badge.dart';

/// Dark-themed event card for the PersonDetailScreen events section.
/// Shows year chip, title, description with gold accents.
/// Tapping navigates to EventDetailScreen.
class EventCard extends StatelessWidget {
  final Event event;

  /// All sibling events (same person) passed through for related-events list.
  final List<Event> relatedEvents;

  const EventCard({
    super.key,
    required this.event,
    this.relatedEvents = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: AppTheme.radiusMd,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              event: event,
              relatedEvents: relatedEvents,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoldBadge.year(event.date),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTheme.sectionTitle.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
