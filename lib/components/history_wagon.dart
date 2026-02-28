import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/history_topic.dart';
import 'xp_badge.dart';

/// Wagon states:
/// - completed: gold check, gold border, XP visible
/// - current:   teal border, pulsing scale, XP visible
/// - locked:    grey, lock icon, disabled tap
class HistoryWagon extends StatefulWidget {
  final HistoryTopic topic;
  final bool isCurrent;
  final VoidCallback? onTap;

  const HistoryWagon({
    super.key,
    required this.topic,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  State<HistoryWagon> createState() => _HistoryWagonState();
}

class _HistoryWagonState extends State<HistoryWagon>
    with SingleTickerProviderStateMixin {
  static const _teal = Color(0xFF5ED8B5);

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant HistoryWagon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topic;
    final locked = t.isLocked;
    final completed = t.isCompleted;
    final current = widget.isCurrent;

    // Resolve colours
    final Color borderColor;
    final Color bodyColor;
    final Color iconBg;
    final Color iconFg;
    final Color titleColor;
    final Color yearColor;

    if (locked) {
      borderColor = AppTheme.divider;
      bodyColor = AppTheme.surfaceLight.withValues(alpha: 0.5);
      iconBg = AppTheme.divider;
      iconFg = AppTheme.textSecondary.withValues(alpha: 0.4);
      titleColor = AppTheme.textSecondary.withValues(alpha: 0.45);
      yearColor = AppTheme.textSecondary.withValues(alpha: 0.35);
    } else if (completed) {
      borderColor = AppTheme.accentGold;
      bodyColor = AppTheme.surface;
      iconBg = AppTheme.accentGold.withValues(alpha: 0.15);
      iconFg = AppTheme.accentGold;
      titleColor = AppTheme.textPrimary;
      yearColor = AppTheme.accentGold;
    } else {
      // current / unlocked
      borderColor = _teal;
      bodyColor = AppTheme.surface;
      iconBg = _teal.withValues(alpha: 0.15);
      iconFg = _teal;
      titleColor = AppTheme.textPrimary;
      yearColor = _teal;
    }

    Widget card = GestureDetector(
      onTap: locked ? null : widget.onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bodyColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: borderColor, width: 1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(
                locked
                    ? Icons.lock_rounded
                    : completed
                        ? Icons.check_rounded
                        : Icons.play_arrow_rounded,
                color: iconFg,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            // XP badge
            if (!locked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: XPBadge(
                  xp: t.xp,
                  compact: true,
                  color: completed ? AppTheme.accentGold : _teal,
                ),
              ),
            // Title
            Text(
              t.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.captionBold.copyWith(
                color: titleColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            // Year pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: yearColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                t.year,
                style: AppTheme.chip.copyWith(
                  color: yearColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (current) {
      card = ScaleTransition(scale: _pulse, child: card);
    }

    return card;
  }
}
