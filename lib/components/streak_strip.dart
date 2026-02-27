import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// D) Progress / Streak strip – 358×52, radius 16
/// Left: Streak 🔥, Center: animated progress bar 140×6, Right: Badges.
class StreakStrip extends StatefulWidget {
  final int streak;
  final double progress; // 0.0–1.0
  final int badges;

  const StreakStrip({
    super.key,
    this.streak = 7,
    this.progress = 0.62,
    this.badges = 3,
  });

  @override
  State<StreakStrip> createState() => _StreakStripState();
}

class _StreakStripState extends State<StreakStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            // ── Streak ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${widget.streak} өдөр',
                  style: AppTheme.captionBold.copyWith(
                    color: AppTheme.streakOrange,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Animated progress bar ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Явц',
                  style: AppTheme.chip.copyWith(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    return SizedBox(
                      width: 120,
                      height: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _progressAnim.value,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.accentGold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const Spacer(),

            // ── Badges ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${widget.badges}',
                  style: AppTheme.captionBold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple AnimatedBuilder stand-in (AnimatedBuilder exists in Flutter already).
/// If the name clashes, we can just use AnimatedBuilder directly.
