import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/person.dart';
import 'glass_card.dart';
import 'gold_badge.dart';

/// Glassmorphism person card for the PersonsScreen list.
/// Shows avatar with gold border, name, date range, description, event count.
class PersonCard extends StatefulWidget {
  final Person person;
  final int eventCount;
  final VoidCallback? onTap;

  const PersonCard({
    super.key,
    required this.person,
    this.eventCount = 0,
    this.onTap,
  });

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final hasImage = person.imageUrl != null && person.imageUrl!.isNotEmpty;
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    final yearsText = _buildYears(person);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar with gold ring
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentGold.withOpacity(0.7),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? Image.asset(
                            person.imageUrl!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) =>
                                _buildInitials(initials),
                          )
                        : _buildInitials(initials),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: AppTheme.sectionTitle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (yearsText.isNotEmpty) GoldBadge.year(yearsText),
                          if (widget.eventCount > 0) ...[
                            const SizedBox(width: 8),
                            GoldBadge.eventCount(widget.eventCount),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        person.description,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.accentGold.withOpacity(0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          initials,
          style: AppTheme.sectionTitle.copyWith(
            color: AppTheme.accentGold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _buildYears(Person person) {
    final parts = <String>[];
    if (person.birthDate != null) parts.add(person.birthDate!);
    if (person.deathDate != null) parts.add(person.deathDate!);
    return parts.join(' - ');
  }
}
