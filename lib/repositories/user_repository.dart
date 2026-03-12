// ════════════════════════════════════════════════════════════════
//  UserRepository – pure Firestore data-access layer for users.
//
//  Responsibilities:
//    - Direct Firestore reads / writes for the `users` collection.
//    - Zero business logic (no XP math, no Auth calls).
//    - All methods are instance-based for easy testing / mocking.
//
//  Firestore structure:
//    users/{uid}                      ← AppUser document
//    users/{uid}/achievements/{id}    ← AppAchievement subcollection
//    users/{uid}/culture_progress/{id}
//    users/{uid}/progress/{id}        ← story progress
//
//  Admin usage (getAllUsers, setRole, setActive, deleteUserDoc)
//  requires Firestore Security Rules that permit admin reads.
// ════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/user_activity.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Helpers ────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users.doc(uid);

  // ═══════════════════════════════════════════════════════════════
  //  1. Get current user profile by uid
  // ═══════════════════════════════════════════════════════════════

  /// One-shot fetch. Returns null if the document does not exist.
  Future<AppUser?> getUser(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      if (!snap.exists) return null;
      final achievements = await _loadAchievements(uid);
      return AppUser.fromFirestore(snap, achievements: achievements);
    } catch (e) {
      debugPrint('UserRepository.getUser error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. Real-time stream of a user's profile
  // ═══════════════════════════════════════════════════════════════

  /// Emits [null] when the document does not exist.
  Stream<AppUser?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. Create user document after signup
  // ═══════════════════════════════════════════════════════════════

  /// Creates the Firestore doc for a brand-new user.
  /// Uses [SetOptions.merge] so accidental double-calls are safe.
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    String role = 'user',
    String preferredLanguage = 'mn',
  }) async {
    try {
      await _userDoc(uid).set(
        {
          'uid': uid,
          'name': name,
          'displayName': name,
          'email': email,
          'role': role,
          'photoUrl': null,
          'bio': null,
          'preferredLanguage': preferredLanguage,
          'totalXP': 0,
          'storiesCompleted': 0,
          'quizzesCompleted': 0,
          'darkMode': false,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'lastActiveDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('UserRepository.createUser error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. Update user profile fields
  // ═══════════════════════════════════════════════════════════════

  /// Partial update — only the provided fields are written.
  /// Always stamps `updatedAt` with a server timestamp.
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    try {
      await _userDoc(uid).set(
        {...fields, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('UserRepository.updateUser error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. Update profile image URL
  // ═══════════════════════════════════════════════════════════════

  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await updateUser(uid, {'photoUrl': photoUrl});
  }

  // ═══════════════════════════════════════════════════════════════
  //  6. [Admin] Fetch all users (paginated)
  // ═══════════════════════════════════════════════════════════════

  /// Returns up to [limit] users ordered by [orderBy].
  /// Pass [startAfterDoc] for cursor-based pagination.
  Future<List<AppUser>> getAllUsers({
    int limit = 50,
    String orderBy = 'createdAt',
    DocumentSnapshot? startAfterDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _users.orderBy(orderBy, descending: true).limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snap = await query.get();
      return snap.docs.map((d) => AppUser.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('UserRepository.getAllUsers error: $e');
      return [];
    }
  }

  /// Stream version — emits whenever any user doc changes.
  /// Use sparingly; Firestore charges per document read.
  Stream<List<AppUser>> watchAllUsers({int limit = 100}) {
    return _users
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppUser.fromFirestore(d)).toList());
  }

  // ═══════════════════════════════════════════════════════════════
  //  7. [Admin] Update user role
  // ═══════════════════════════════════════════════════════════════

  /// [role] must be one of: 'user' | 'admin' | 'superAdmin'
  Future<void> setUserRole(String uid, String role) async {
    assert(
      ['user', 'admin', 'superAdmin'].contains(role),
      'Invalid role: $role',
    );
    await updateUser(uid, {'role': role});
  }

  // ═══════════════════════════════════════════════════════════════
  //  8. [Admin] Set user active / inactive
  // ═══════════════════════════════════════════════════════════════

  Future<void> setUserActive(String uid, {required bool isActive}) async {
    await updateUser(uid, {'isActive': isActive});
  }

  // ═══════════════════════════════════════════════════════════════
  //  9. [Admin] Delete user document
  // ═══════════════════════════════════════════════════════════════

  /// Deletes the Firestore document only.
  /// The Firebase Auth account must be deleted separately
  /// (use Firebase Admin SDK on the server side).
  Future<void> deleteUserDoc(String uid) async {
    try {
      await _userDoc(uid).delete();
    } catch (e) {
      debugPrint('UserRepository.deleteUserDoc error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  10. Update last login timestamp
  // ═══════════════════════════════════════════════════════════════

  Future<void> touchLastLogin(String uid) async {
    await updateUser(uid, {'lastLogin': FieldValue.serverTimestamp()});
  }

  // ═══════════════════════════════════════════════════════════════
  //  11. Add XP (atomic increment)
  // ═══════════════════════════════════════════════════════════════

  Future<void> addExp(String uid, int amount) async {
    try {
      await _userDoc(uid).update({
        'totalXP': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('UserRepository.addExp error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  12. Increment story / quiz completed counters
  // ═══════════════════════════════════════════════════════════════

  Future<void> incrementStoriesCompleted(String uid) async {
    await _userDoc(uid).update({
      'storiesCompleted': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementQuizzesCompleted(String uid) async {
    await _userDoc(uid).update({
      'quizzesCompleted': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  13. Favorites subcollection  (users/{uid}/favorites)
  // ═══════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _userDoc(uid).collection('favorites');

  Future<void> addFavorite(String uid, UserFavorite fav) async {
    await _favorites(uid).doc(fav.storyId).set(fav.toFirestore());
  }

  Future<void> removeFavorite(String uid, String storyId) async {
    await _favorites(uid).doc(storyId).delete();
  }

  Future<bool> isFavorite(String uid, String storyId) async {
    final doc = await _favorites(uid).doc(storyId).get();
    return doc.exists;
  }

  Future<List<UserFavorite>> getFavorites(String uid, {int limit = 50}) async {
    try {
      final snap = await _favorites(uid)
          .orderBy('savedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => UserFavorite.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('UserRepository.getFavorites error: $e');
      return [];
    }
  }

  Stream<List<UserFavorite>> watchFavorites(String uid) {
    return _favorites(uid).orderBy('savedAt', descending: true).snapshots().map(
        (snap) => snap.docs.map((d) => UserFavorite.fromFirestore(d)).toList());
  }

  // ═══════════════════════════════════════════════════════════════
  //  14. History subcollection  (users/{uid}/history)
  // ═══════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _userDoc(uid).collection('history');

  /// Tracks a story view. Uses storyId as doc id so re-views just update the
  /// timestamp instead of creating duplicates.
  Future<void> trackViewed(String uid, UserHistory entry) async {
    await _history(uid).doc(entry.storyId).set(entry.toFirestore());
  }

  Future<List<UserHistory>> getHistory(String uid, {int limit = 50}) async {
    try {
      final snap = await _history(uid)
          .orderBy('viewedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => UserHistory.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('UserRepository.getHistory error: $e');
      return [];
    }
  }

  Stream<List<UserHistory>> watchHistory(String uid) {
    return _history(uid).orderBy('viewedAt', descending: true).snapshots().map(
        (snap) => snap.docs.map((d) => UserHistory.fromFirestore(d)).toList());
  }

  // ═══════════════════════════════════════════════════════════════
  //  Private helpers
  // ═══════════════════════════════════════════════════════════════

  Future<List<AppAchievement>> _loadAchievements(String uid) async {
    try {
      final snap = await _userDoc(uid).collection('achievements').get();
      final list = snap.docs.map(AppAchievement.fromFirestore).toList();
      list.sort((a, b) {
        if (a.unlocked && !b.unlocked) return -1;
        if (!a.unlocked && b.unlocked) return 1;
        if (a.unlockedAt != null && b.unlockedAt != null) {
          return b.unlockedAt!.compareTo(a.unlockedAt!);
        }
        return 0;
      });
      return list;
    } catch (_) {
      return [];
    }
  }
}
