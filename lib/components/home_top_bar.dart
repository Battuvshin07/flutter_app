// ════════════════════════════════════════════════════════
//  HomeTopBar – live Firestore data, no hardcoded values
//   Profile avatar with initials fallback
//   Level badge + mini XP progress bar from totalXP
//   Notification bell – NO badge
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/xp_helpers.dart' as xp;

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

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
      child: StreamBuilder<AppUser?>(
        stream: UserService.watchCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final totalXP = user?.totalXP ?? 0;
          final level = xp.levelFromXP(totalXP);
          final progress = xp.levelProgress(totalXP);
          final xpInto = xp.xpIntoCurrentLevel(totalXP);
          final xpNeeded = xp.xpNeededForNextLevel(totalXP);
          final photoUrl = user?.photoUrl;
          final _displayName =
              FirebaseAuth.instance.currentUser?.displayName ?? '';
          final initials = user?.initials ??
              (_displayName.isNotEmpty
                  ? _displayName.substring(0, 1).toUpperCase()
                  : '?');
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  user == null;

          return Row(
            children: [
              // ── Profile circle ──────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGold, width: 2),
                ),
                child: ClipOval(
                  child: (photoUrl?.isNotEmpty == true)
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _InitialsCircle(initials: initials),
                        )
                      : _InitialsCircle(initials: initials),
                ),
              ),

              const Spacer(),

              // ── Level + XP chip ─────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    const Text(
                      '•',
                      style:
                          TextStyle(color: AppTheme.textSecondary, fontSize: 8),
                    ),
                    const SizedBox(width: 8),
                    // Mini XP progress bar
                    SizedBox(
                      width: 48,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.accentGold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLoading ? '…xp' : '$xpInto/$xpNeeded xp',
                      style: AppTheme.chip
                          .copyWith(color: AppTheme.accentGold, fontSize: 10),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}

// ── Initials avatar for when no photoUrl is available ───────────────
class _InitialsCircle extends StatelessWidget {
  final String initials;
  const _InitialsCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceLight,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppTheme.accentGold,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
