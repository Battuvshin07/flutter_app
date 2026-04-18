import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        'preferredLanguage': 'mn',
        'totalXP': 0,
        'storiesCompleted': 0,
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
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Sign in with Google account.
  /// Creates or updates Firestore user doc on success.
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final docRef = _db.doc('users/${user.uid}');
      final doc = await docRef.get();

      if (doc.exists) {
        // Existing user — update last login
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // New user — create Firestore profile
        await docRef.set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'user',
          'isActive': true,
          'avatarUrl': '',
          'photoUrl': user.photoURL,
          'preferredLanguage': 'mn',
          'totalXP': 0,
          'storiesCompleted': 0,
          'lastLogin': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return user;
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Send email verification to current user.
  /// Call this right after signup or when user requests re-verification.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Нэвтэрсэн хэрэглэгч олдсонгүй.',
      );
    }

    if (user.emailVerified) {
      throw FirebaseAuthException(
        code: 'already-verified',
        message: 'Имэйл аль хэдийн баталгаажсан байна.',
      );
    }

    await user.sendEmailVerification();
  }

  /// Reload current user to check if email is verified.
  /// Returns true if verified, false otherwise.
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    return refreshedUser?.emailVerified ?? false;
  }

  /// Check if current user's email is verified.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Change password for email/password users.
  /// 1. Re-authenticates with [currentPassword].
  /// 2. Updates Firebase Auth password to [newPassword].
  /// 3. Stamps `updatedAt` in the Firestore user doc.
  ///
  /// Throws [FirebaseAuthException] on wrong password or weak password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Нэвтэрсэн хэрэглэгч олдсонгүй.',
      );
    }

    // Re-authenticate before the sensitive operation.
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update the password in Firebase Auth.
    await user.updatePassword(newPassword);

    // Reflect the change in the Firestore profile document.
    await _db.doc('users/${user.uid}').update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
