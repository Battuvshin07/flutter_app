// ════════════════════════════════════════════════════════
//  UserService – Firestore + Firebase Auth user layer
//  Provides:
//    • XP / Level helpers
//    • Real-time stream of current user
//    • One-shot fetch & doc seeding
//    • Debug data seeder (debug builds only)
// ════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class UserService {
  UserService._(); // static-only

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Helpers ──────────────────────────────────────────────────────
  static String? get _uid => _auth.currentUser?.uid;

  // ═══════════════════════════════════════════════════════════════
  //  XP → Level formulæ
  //  Level 1 starts at 0 XP.
  //  Gap between level N and N+1 = 1000 + (N-1)*250
  //
  //  Examples:
  //    Lv 1 → Lv 2 : 1000 XP
  //    Lv 2 → Lv 3 : 1250 XP
  //    Lv 3 → Lv 4 : 1500 XP   …and so on.
  // ═══════════════════════════════════════════════════════════════

  /// Total XP required to *reach* [level] (level starts at 1).
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    int total = 0;
    for (int i = 2; i <= level; i++) {
      total += 1000 + (i - 2) * 250;
    }
    return total;
  }

  /// Current level derived from [totalXP].
  static int levelFromXP(int totalXP) {
    if (totalXP <= 0) return 1;
    int level = 1;
    while (xpForLevel(level + 1) <= totalXP) {
      level++;
    }
    return level;
  }

  /// Fractional progress within the current level [0.0 – 1.0].
  static double levelProgress(int totalXP) {
    if (totalXP <= 0) return 0.0;
    final level = levelFromXP(totalXP);
    final currentLevelXP = xpForLevel(level);
    final nextLevelXP = xpForLevel(level + 1);
    final span = nextLevelXP - currentLevelXP;
    if (span <= 0) return 1.0;
    return ((totalXP - currentLevelXP) / span).clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  //  Firestore streams / fetches
  // ═══════════════════════════════════════════════════════════════

  /// Real-time stream of the signed-in user's profile doc.
  /// Emits [null] when not authenticated or doc does not exist.
  static Stream<AppUser?> watchCurrentUser() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  /// One-shot fetch of the current user's profile.
  static Future<AppUser?> getCurrentUser() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) return null;
      final achievements = await loadAchievements(uid);
      return AppUser.fromFirestore(snap, achievements: achievements);
    } catch (e) {
      debugPrint('UserService.getCurrentUser error: $e');
      return null;
    }
  }

  /// Fetch achievements subcollection for [uid].
  static Future<List<AppAchievement>> loadAchievements(String uid) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .get();
      return snap.docs.map(AppAchievement.fromFirestore).toList();
    } catch (e) {
      debugPrint('UserService.loadAchievements error: $e');
      return [];
    }
  }

  /// Real-time stream of achievements subcollection.
  static Stream<List<AppAchievement>> watchAchievements() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppAchievement.fromFirestore).toList());
  }

  // ═══════════════════════════════════════════════════════════════
  //  Doc seeding – call after first login / sign-up
  // ═══════════════════════════════════════════════════════════════

  /// Ensures a Firestore user doc exists with all required fields.
  /// Merges missing fields without overwriting existing data.
  static Future<void> ensureUserDocExists() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      final docRef = _db.collection('users').doc(uid);
      final snap = await docRef.get();

      final defaults = <String, dynamic>{
        'uid': uid,
        'name': user.displayName ?? 'Хэрэглэгч',
        'email': user.email ?? '',
        'role': 'user',
        'isActive': true,
        'totalXP': 0,
        'streakDays': 0,
        'progress': <String, dynamic>{
          'humans': 0.0,
          'history': 0.0,
          'map': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (!snap.exists) {
        await docRef.set(defaults);
      } else {
        // Patch only genuinely missing fields
        final existing = snap.data() ?? {};
        final patch = <String, dynamic>{};

        void addIfMissing(String key, dynamic value) {
          if (!existing.containsKey(key)) patch[key] = value;
        }

        addIfMissing('totalXP', 0);
        addIfMissing('streakDays', 0);
        addIfMissing('progress', <String, dynamic>{
          'humans': 0.0,
          'history': 0.0,
          'map': 0.0,
        });
        addIfMissing('isActive', true);
        patch['updatedAt'] = FieldValue.serverTimestamp();

        if (patch.isNotEmpty) {
          await docRef.update(patch);
        }
      }
    } catch (e) {
      debugPrint('UserService.ensureUserDocExists error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  Debug seeder – populates fake data for UI testing
  //  Only callable in debug builds (kDebugMode = true)
  // ═══════════════════════════════════════════════════════════════

  /// Seeds realistic-looking data into the current user's Firestore doc
  /// and achievements subcollection. For testing only.
  static Future<void> seedDebugData() async {
    assert(kDebugMode, 'seedDebugData must only be called in debug builds');
    final uid = _uid;
    if (uid == null) return;

    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);

    // Update user doc with sample data
    batch.update(userRef, {
      'totalXP': 18400,
      'streakDays': 7,
      'progress': {
        'humans': 0.85,
        'history': 0.60,
        'map': 0.92,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Seed achievements
    final achievementsRef = userRef.collection('achievements');
    final sampleAchievements = [
      {
        'title': 'Алтан цом',
        'icon': 'trophy',
        'unlockedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
      },
      {
        'title': 'Хамгаалагч',
        'icon': 'shield',
        'unlockedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
      },
      {
        'title': 'Медаль',
        'icon': 'medal',
        'unlockedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
      },
      {
        'title': 'Од',
        'icon': 'star',
        'unlockedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 12)),
        ),
      },
    ];

    for (final a in sampleAchievements) {
      batch.set(achievementsRef.doc(), a);
    }

    await batch.commit();
    debugPrint('UserService.seedDebugData: seeded for uid=$uid');
  }
}
