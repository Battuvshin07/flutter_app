// ════════════════════════════════════════════════════════════════
//  AchievementService – business logic for checking / unlocking
//  achievements and granting EXP rewards.
//
//  Call [checkAndUnlock] after any user-stat-changing event
//  (story complete, quiz complete, XP change, streak update).
// ════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import '../models/achievement_definition.dart';
import '../models/app_user.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/user_repository.dart';

class AchievementService {
  AchievementService({
    AchievementRepository? achievementRepo,
    UserRepository? userRepo,
  })  : _achievementRepo = achievementRepo ?? AchievementRepository(),
        _userRepo = userRepo ?? UserRepository();

  final AchievementRepository _achievementRepo;
  final UserRepository _userRepo;

  /// Load all master definitions (cached for the session).
  List<AchievementDefinition>? _cachedDefinitions;

  Future<List<AchievementDefinition>> _definitions() async {
    _cachedDefinitions ??= await _achievementRepo.getAllDefinitions();
    return _cachedDefinitions!;
  }

  /// Check all achievement conditions against the current user stats
  /// and unlock any that are newly met.
  /// Returns the list of newly unlocked [AchievementDefinition]s.
  Future<List<AchievementDefinition>> checkAndUnlock(AppUser user) async {
    final definitions = await _definitions();
    final existing = await _achievementRepo.getUserAchievements(user.id);
    final existingIds = existing.map((a) => a.id).toSet();

    final newlyUnlocked = <AchievementDefinition>[];

    for (final def in definitions) {
      if (existingIds.contains(def.id)) continue;
      if (!_isMet(def, user)) continue;

      await _achievementRepo.unlockAchievement(
        uid: user.id,
        definition: def,
      );

      if (def.expReward > 0) {
        await _userRepo.addExp(user.id, def.expReward);
      }

      newlyUnlocked.add(def);
    }

    if (newlyUnlocked.isNotEmpty) {
      debugPrint(
        'AchievementService: unlocked ${newlyUnlocked.length} '
        'achievement(s) for uid=${user.id}',
      );
    }

    return newlyUnlocked;
  }

  bool _isMet(AchievementDefinition def, AppUser user) {
    switch (def.conditionType) {
      case 'stories_completed':
        return user.storiesCompleted >= def.conditionValue;
      case 'quizzes_completed':
        return user.quizzesCompleted >= def.conditionValue;
      case 'xp_total':
        return user.totalXP >= def.conditionValue;
      case 'level':
        return user.level >= def.conditionValue;
      default:
        return false;
    }
  }
}
