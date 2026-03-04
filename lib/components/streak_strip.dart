// ════════════════════════════════════════════════════════
//  StreakStrip – live Firestore data
//   Left  : streakDays from users/{uid}
//   Center: XP level progress bar from totalXP
//   Right : count of unlocked achievements
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/xp_helpers.dart' as xp;

class StreakStrip extends StatefulWidget {
  const StreakStrip({super.key});

  @override
  State<StreakStrip> createState() => _StreakStripState();
}

class _StreakStripState extends State<StreakStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  // Cached values that drive the animation target
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    if ((target - _targetProgress).abs() < 0.005) return;
    _targetProgress = target;
    _progressAnim = Tween<double>(begin: _progressAnim.value, end: target)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: UserService.watchCurrentUser(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final streakDays = user?.streakDays ?? 0;
        final totalXP = user?.totalXP ?? 0;
        final progress = xp.levelProgress(totalXP);

        // Trigger animation when progress changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateTo(progress);
        });

        return StreamBuilder<List<AppAchievement>>(
          stream: UserService.watchAchievements(),
          builder: (context, achSnap) {
            final achievements = achSnap.data ?? [];
            final unlockedCount = achievements.where((a) => a.unlocked).length;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
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
                    // ── Streak ────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '$streakDays өдөр',
                          style: AppTheme.captionBold.copyWith(
                            color: AppTheme.streakOrange,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ── Animated XP progress bar ───────────────
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

                    // ── Unlocked achievements badge count ──────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '$unlockedCount',
                          style: AppTheme.captionBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
