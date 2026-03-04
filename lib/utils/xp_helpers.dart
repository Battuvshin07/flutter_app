// ════════════════════════════════════════════════════════
//  XP Helpers – shared level/XP calculation utilities
//  Used on Home screen and Profile screen.
//
//  Formula:
//    Level 1 starts at 0 XP.
//    XP needed to go from level N → N+1 = 1000 + (N-1) × 250
//    Level 1→2:  1 000 XP          Level 5→6:  2 000 XP
//    Level 2→3:  1 250 XP          Level 6→7:  2 250 XP  …
// ════════════════════════════════════════════════════════

/// Total XP required to *reach* [level] (level 1 = 0 XP).
int xpForLevel(int level) {
  if (level <= 1) return 0;
  int total = 0;
  for (int i = 2; i <= level; i++) {
    total += 1000 + (i - 2) * 250;
  }
  return total;
}

/// Current level derived from [totalXP]. Always ≥ 1.
int levelFromXP(int totalXP) {
  if (totalXP <= 0) return 1;
  int level = 1;
  while (xpForLevel(level + 1) <= totalXP) {
    level++;
  }
  return level;
}

/// XP earned inside the current level (0-based starting from level floor).
int xpIntoCurrentLevel(int totalXP) {
  final level = levelFromXP(totalXP);
  return totalXP - xpForLevel(level);
}

/// XP required to complete the current level (gap to next level).
int xpNeededForNextLevel(int totalXP) {
  final level = levelFromXP(totalXP);
  return xpForLevel(level + 1) - xpForLevel(level);
}

/// Fractional progress within the current level [0.0 – 1.0].
double levelProgress(int totalXP) {
  if (totalXP <= 0) return 0.0;
  final into = xpIntoCurrentLevel(totalXP);
  final needed = xpNeededForNextLevel(totalXP);
  if (needed <= 0) return 1.0;
  return (into / needed).clamp(0.0, 1.0);
}
