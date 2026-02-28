import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Determines the user's role from Firestore and/or Custom Claims.
///
/// Uses a hybrid strategy:
///   1. Try Custom Claims first (zero-cost, authoritative).
///   2. Fall back to Firestore `users/{uid}.role` field.
class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the role for the currently signed-in user.
  /// Returns `'admin'`, `'user'`, or `null` if not found.
  Future<String?> getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // 1) Check Custom Claims (preferred — set via Cloud Function)
    final tokenResult = await user.getIdTokenResult(true);
    final claimRole = tokenResult.claims?['role'];
    if (claimRole != null &&
        (claimRole == 'admin' ||
            claimRole == 'superAdmin' ||
            claimRole == 'user')) {
      return claimRole as String;
    }

    // 2) Fallback: read from Firestore user doc
    final doc = await _db.doc('users/${user.uid}').get();
    if (doc.exists) {
      return doc.data()?['role'] as String? ?? 'user';
    }

    return 'user'; // default
  }

  /// Check if the current user is an admin or superAdmin.
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'superAdmin';
  }

  /// Stream that re-emits the role whenever the Firestore user doc changes.
  /// Useful for real-time role updates from the admin panel.
  Stream<String> roleStream(String uid) {
    return _db.doc('users/$uid').snapshots().map((snap) {
      if (!snap.exists) return 'user';
      return snap.data()?['role'] as String? ?? 'user';
    });
  }
}
