import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact XP badge with diamond icon and value.
/// Used on history wagons and journey screens.
class XPBadge extends StatelessWidget {
  final int xp;
  final bool compact;
  final Color? color;

  const XPBadge({
    super.key,
    required this.xp,
    this.compact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.accentGold;
    final size = compact ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, size: size + 2, color: accent),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: AppTheme.chip.copyWith(
              color: accent,
              fontSize: size,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
