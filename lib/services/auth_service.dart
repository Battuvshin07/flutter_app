import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';

/// Firebase Authentication service.
/// Handles sign-up, sign-in, sign-out, and auth state stream.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Current Firebase user (null if signed out).
  User? get currentUser => _auth.currentUser;

  /// Stream that emits on every auth state change (sign-in / sign-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email + password.
  /// Creates a Firestore profile doc at `users/{uid}` with role = "user".
  Future<User?> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      // Update display name in Auth
      await user.updateDisplayName(name);

      // Create Firestore user profile (includes all required fields)
      await _db.doc('users/${user.uid}').set({
        'uid': user.uid,
        'name': name,
        'displayName': name,
        'email': email,
        'role': 'user',
        'isActive': true,
        'avatarUrl': '',
        'photoUrl': null,
        'bio': null,
        'preferredLanguage': 'mn',
        'totalXP': 0,
        'streakDays': 0,
        'progress': <String, dynamic>{
          'humans': 0.0,
          'history': 0.0,
          'map': 0.0,
        },
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  /// Sign in an existing user with email + password.
  /// Updates `lastLogin` timestamp in Firestore.
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      // Ensure doc exists (handles accounts created before field additions)
      await UserService.ensureUserDocExists();
      // Update last login
      await _db.doc('users/${user.uid}').update({
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
