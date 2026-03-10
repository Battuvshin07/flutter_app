import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../components/glass_card.dart';
import '../components/gold_badge.dart';

// ══════════════════════════════════════════════════════════════════
//  EVENT DETAIL SCREEN
//  Blog/article-style reading layout for historical events.
//  Consistent with PersonDetailScreen design language.
// ══════════════════════════════════════════════════════════════════

class EventDetailScreen extends StatelessWidget {
  final Event event;

  /// Pass all events for the same person so we can show related events.
  final List<Event> relatedEvents;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.relatedEvents = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Filter related: same personId, exclude self
    final related =
        relatedEvents.where((e) => e.eventId != event.eventId).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, Color(0xFF0D1628)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppBar(event: event),
                _TitleSection(event: event),
                _IllustrationCard(event: event),
                _ArticleContent(event: event),
                if (related.isNotEmpty) _RelatedEvents(events: related),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  APP BAR
// ══════════════════════════════════════════════════════════════════

class _AppBar extends StatefulWidget {
  final Event event;
  const _AppBar({required this.event});

  @override
  State<_AppBar> createState() => _AppBarState();
}

class _AppBarState extends State<_AppBar> {
  bool _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              widget.event.title,
              textAlign: TextAlign.center,
              style: AppTheme.h2.copyWith(fontSize: 17),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Bookmark button
          GestureDetector(
            onTap: () => setState(() => _bookmarked = !_bookmarked),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Icon(
                _bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TITLE SECTION — Large title + metadata badges
// ══════════════════════════════════════════════════════════════════

class _TitleSection extends StatelessWidget {
  final Event event;
  const _TitleSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large bold title
          Text(
            event.title,
            style: AppTheme.h2.copyWith(fontSize: 26, height: 1.25),
          ),
          const SizedBox(height: 12),

          // Metadata row: year + category
          Row(
            children: [
              // Year badge
              GoldBadge(
                text: event.date,
                icon: Icons.calendar_today_rounded,
                backgroundColor: AppTheme.accentGold.withValues(alpha: 0.12),
                textColor: AppTheme.accentGold,
                fontSize: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
              const SizedBox(width: 10),
              // Category badge
              GoldBadge(
                text: 'Түүхэн үйл явдал',
                icon: Icons.emoji_events_outlined,
                backgroundColor: AppTheme.surface,
                textColor: AppTheme.textSecondary,
                fontSize: 11,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ILLUSTRATION CARD — Full-width image with gradient overlay
// ══════════════════════════════════════════════════════════════════

class _IllustrationCard extends StatelessWidget {
  final Event event;
  const _IllustrationCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.18),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or placeholder
              if (hasImage)
                Image.network(
                  event.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),

              // Bottom gradient overlay for readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.background.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Year chip on top-left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: AppTheme.accentGold),
                      const SizedBox(width: 5),
                      Text(
                        event.date,
                        style: AppTheme.chip.copyWith(
                          color: AppTheme.accentGold,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 56,
            color: AppTheme.accentGold.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Зураг байхгүй',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ARTICLE CONTENT — Blog-style text body
// ══════════════════════════════════════════════════════════════════

class _ArticleContent extends StatelessWidget {
  final Event event;
  const _ArticleContent({required this.event});

  // Split description into intro + body paragraphs for richer layout
  List<String> get _paragraphs {
    final text = event.description.trim();
    if (text.isEmpty) return [];
    // Split on double newline or sentence boundary > 80 chars
    final parts = text.split(RegExp(r'\n\n+'));
    if (parts.length > 1) return parts;
    // Single block: show as-is
    return [text];
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = _paragraphs;
    if (paragraphs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        glowColor: AppTheme.accentGold,
        glowIntensity: 0.04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(Icons.auto_stories_rounded,
                    size: 18, color: AppTheme.accentGold.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text('Түүхэн тойм', style: AppTheme.sectionTitle),
              ],
            ),
            Divider(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              thickness: 1,
              height: 20,
            ),

            // First paragraph (intro) — slightly highlighted
            Text(
              paragraphs.first,
              style: AppTheme.body.copyWith(
                height: 1.7,
                color: AppTheme.textPrimary.withValues(alpha: 0.9),
              ),
            ),

            // Remaining paragraphs with a subtitle divider
            if (paragraphs.length > 1) ...[
              const SizedBox(height: 16),
              _sectionSubtitle('Нэмэлт мэдээлэл'),
              const SizedBox(height: 12),
              ...paragraphs.skip(1).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        p,
                        style: AppTheme.body.copyWith(height: 1.7),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionSubtitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.accentGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.captionBold.copyWith(
            fontSize: 13,
            color: AppTheme.accentGold,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  RELATED EVENTS — Card list, each navigates to its own detail
// ══════════════════════════════════════════════════════════════════

class _RelatedEvents extends StatelessWidget {
  final List<Event> events;
  const _RelatedEvents({required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.event_note_rounded,
                size: 18,
                color: AppTheme.accentGold.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text('Холбогдсон үйл явдлууд', style: AppTheme.sectionTitle),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppTheme.accentGold.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card list
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RelatedEventTile(event: e, allRelated: events),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedEventTile extends StatelessWidget {
  final Event event;
  final List<Event> allRelated;

  const _RelatedEventTile({
    required this.event,
    required this.allRelated,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppTheme.radiusMd,
      glowIntensity: 0.0,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            event: event,
            relatedEvents: allRelated,
          ),
        ),
      ),
      child: Row(
        children: [
          // Arrow icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 12),

          // Title + year
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTheme.captionBold.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.date,
                  style: AppTheme.caption.copyWith(
                    fontSize: 11,
                    color: AppTheme.accentGold.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
