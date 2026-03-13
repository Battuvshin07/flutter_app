// ════════════════════════════════════════════════════════
//  XP Helpers – shared level/XP calculation utilities
//  Used on Home screen and Profile screen.
//
//  Formula:
//    Level 1 starts at 0 XP.
//    XP needed to go from level N → N+1 = N × 100
//    Level 1→2:   100 XP          Level 6→7:   600 XP
//    Level 2→3:   200 XP          Level 7→8:   700 XP
//    Level 3→4:   300 XP          Level 8→9:   800 XP
//    Level 9→10:  900 XP          Level 10→11: 1000 XP
// ════════════════════════════════════════════════════════

/// Total XP required to *reach* [level] (level 1 = 0 XP).
int xpForLevel(int level) {
  if (level <= 1) return 0;
  int total = 0;
  for (int i = 1; i < level; i++) {
    total += i * 100;
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
