import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Manages the current user's profile data in Firestore (users/{uid}).
class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _displayName;
  String? _photoUrl;
  String? _bio;
  String? _preferredLanguage;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────
  String? get displayName => _displayName;
  String? get photoUrl => _photoUrl;
  String? get bio => _bio;
  String? get preferredLanguage => _preferredLanguage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _uid => _auth.currentUser?.uid;

  // ── Load profile from Firestore ──────────────────────────────
  Future<void> loadProfile() async {
    final uid = _uid;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _displayName =
            data['displayName'] as String? ?? _auth.currentUser?.displayName;
        _photoUrl = data['photoUrl'] as String? ?? _auth.currentUser?.photoURL;
        _bio = data['bio'] as String?;
        _preferredLanguage = data['preferredLanguage'] as String?;
      } else {
        _displayName = _auth.currentUser?.displayName;
        _photoUrl = _auth.currentUser?.photoURL;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('ProfileProvider.loadProfile error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Update profile (Firestore + Auth + optional avatar) ──────
  Future<bool> updateProfile({
    required String displayName,
    String? bio,
    String? preferredLanguage,
    Uint8List? avatarBytes,
  }) async {
    final uid = _uid;
    if (uid == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? newPhotoUrl = _photoUrl;

      // Upload avatar to Firebase Storage if new bytes provided
      if (avatarBytes != null) {
        final ref = _storage.ref().child('users/$uid/avatar.jpg');
        await ref.putData(
          avatarBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        newPhotoUrl = await ref.getDownloadURL();
      }

      final data = <String, dynamic>{
        'displayName': displayName,
        'bio': bio ?? '',
        'preferredLanguage': preferredLanguage ?? 'mn',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newPhotoUrl != null) {
        data['photoUrl'] = newPhotoUrl;
      }

      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

      // Sync with Firebase Auth profile
      await _auth.currentUser?.updateDisplayName(displayName);
      if (newPhotoUrl != null) {
        await _auth.currentUser?.updatePhotoURL(newPhotoUrl);
      }

      _displayName = displayName;
      _photoUrl = newPhotoUrl;
      _bio = bio;
      _preferredLanguage = preferredLanguage;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('ProfileProvider.updateProfile error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
