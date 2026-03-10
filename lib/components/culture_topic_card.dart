import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Dark-themed culture topic card with glowing icon,
/// title, description, and chevron.
class CultureTopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback? onTap;

  const CultureTopicCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor = AppTheme.accentGold,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon container with glow
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.sectionTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.caption.copyWith(height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary.withValues(alpha: 0.45),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
