import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A) Top App Bar – 96pt height
/// Profile circle (left), Level+XP chip (center), bell icon (right).
class HomeTopBar extends StatelessWidget {
  final int level;
  final int currentXp;
  final int maxXp;

  const HomeTopBar({
    super.key,
    this.level = 5,
    this.currentXp = 120,
    this.maxXp = 244,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      height: 96 + topPad,
      padding: EdgeInsets.only(
        top: topPad + 8,
        left: AppTheme.pagePadding,
        right: AppTheme.pagePadding,
        bottom: 8,
      ),
      color: AppTheme.background,
      child: Row(
        children: [
          // ── Profile circle ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentGold, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/pic_1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const Spacer(),

          // ── Level + XP chip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Level $level', style: AppTheme.chip),
                const SizedBox(width: 8),
                const Text('•',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
                const SizedBox(width: 8),
                // Mini XP bar
                SizedBox(
                  width: 48,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: currentXp / maxXp,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.accentGold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${currentXp}xp',
                  style: AppTheme.chip
                      .copyWith(color: AppTheme.accentGold, fontSize: 10),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Notifications ──
          _CircleButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            badgeCount: 2,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(icon, color: AppTheme.textPrimary, size: 18),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppTheme.crimson,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
