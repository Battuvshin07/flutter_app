import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'gold_badge.dart';

/// Dark-themed timeline event card with year badge,
/// title, description, and optional linked-person chip.
class TimelineEventCard extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  final String? personName;
  final VoidCallback? onTap;

  const TimelineEventCard({
    super.key,
    required this.date,
    required this.title,
    required this.description,
    this.personName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          GoldBadge.year(date),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: AppTheme.sectionTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            description,
            style: AppTheme.body.copyWith(fontSize: 13, height: 1.45),
          ),
          // Person link
          if (personName != null && personName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppTheme.accentGold.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    personName!,
                    style: AppTheme.chip.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
