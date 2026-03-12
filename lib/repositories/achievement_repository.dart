// ════════════════════════════════════════════════════════════════
//  AchievementRepository – Firestore data-access for achievements.
//
//  Two collections:
//    achievements/{id}                 ← master definitions
//    users/{uid}/achievements/{id}     ← per-user unlock state
// ════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement_definition.dart';
import '../models/app_user.dart';

class AchievementRepository {
  AchievementRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Master definitions ────────────────────────────────────────

  Future<List<AchievementDefinition>> getAllDefinitions() async {
    try {
      final snap =
          await _db.collection('achievements').orderBy('sortOrder').get();
      return snap.docs
          .map((d) => AchievementDefinition.fromFirestore(d))
          .toList();
    } catch (e) {
      debugPrint('AchievementRepository.getAllDefinitions error: $e');
      return [];
    }
  }

  Stream<List<AchievementDefinition>> watchDefinitions() {
    return _db.collection('achievements').orderBy('sortOrder').snapshots().map(
        (snap) => snap.docs
            .map((d) => AchievementDefinition.fromFirestore(d))
            .toList());
  }

  // ── Per-user achievements ─────────────────────────────────────

  Future<List<AppAchievement>> getUserAchievements(String uid) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .get();
      return snap.docs.map(AppAchievement.fromFirestore).toList();
    } catch (e) {
      debugPrint('AchievementRepository.getUserAchievements error: $e');
      return [];
    }
  }

  Stream<List<AppAchievement>> watchUserAchievements(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .snapshots()
        .map((snap) => snap.docs.map(AppAchievement.fromFirestore).toList());
  }

  /// Unlock an achievement for the user. Uses the definition id as doc id
  /// so each achievement can only be unlocked once.
  Future<void> unlockAchievement({
    required String uid,
    required AchievementDefinition definition,
  }) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc(definition.id);

    final existing = await ref.get();
    if (existing.exists) return; // already unlocked

    await ref.set({
      'title': definition.title,
      'icon': definition.icon,
      'unlocked': true,
      'unlockedAt': FieldValue.serverTimestamp(),
    });
  }
}
