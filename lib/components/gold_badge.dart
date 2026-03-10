import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable gold-accent badge chip for dates, XP, labels, etc.
class GoldBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const GoldBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  /// Factory for birth date chip (green-ish tint).
  factory GoldBadge.birth(String date) {
    return GoldBadge(
      text: date,
      icon: Icons.cake_outlined,
      backgroundColor: const Color(0xFF1B3328),
      textColor: AppTheme.xpGreen,
    );
  }

  /// Factory for death date chip (crimson tint).
  factory GoldBadge.death(String date) {
    return GoldBadge(
      text: date,
      icon: Icons.history,
      backgroundColor: const Color(0xFF3B1F2B),
      textColor: AppTheme.crimson,
    );
  }

  /// Factory for XP badge.
  factory GoldBadge.xp(int xp) {
    return GoldBadge(
      text: '${_formatNumber(xp)} XP',
      icon: Icons.emoji_events_outlined,
      backgroundColor: AppTheme.accentGold.withValues(alpha: 0.15),
      textColor: AppTheme.accentGold,
      fontSize: 12,
    );
  }

  /// Factory for event count badge.
  factory GoldBadge.eventCount(int count) {
    return GoldBadge(
      text: '$count үйл явдал',
      icon: Icons.event_note_outlined,
      backgroundColor: const Color(0xFF1E2D45),
      textColor: const Color(0xFF64B5F6),
      fontSize: 10,
    );
  }

  /// Factory for year chip.
  factory GoldBadge.year(String year) {
    return GoldBadge(
      text: year,
      backgroundColor: AppTheme.accentGold.withValues(alpha: 0.15),
      textColor: AppTheme.accentGold,
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000) {
      final str = n.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.accentGold.withValues(alpha: 0.15);
    final fg = textColor ?? AppTheme.accentGold;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTheme.chip.copyWith(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
