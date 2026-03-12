import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_user.dart';
import '../models/user_activity.dart';
import '../repositories/user_repository.dart';

/// Manages the current user's profile data in Firestore (users/{uid}).
class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserRepository _repo = UserRepository();

  AppUser? _user;
  String? _displayName;
  String? _photoUrl;
  String? _bio;
  String? _preferredLanguage;
  bool _isLoading = false;
  String? _error;
  List<UserFavorite> _favorites = [];
  List<UserHistory> _history = [];

  // ── Getters ──────────────────────────────────────────────────
  AppUser? get user => _user;
  String? get displayName => _displayName;
  String? get photoUrl => _photoUrl;
  String? get bio => _bio;
  String? get preferredLanguage => _preferredLanguage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserFavorite> get favorites => _favorites;
  List<UserHistory> get history => _history;
  int get totalXP => _user?.totalXP ?? 0;
  int get level => _user?.level ?? 1;
  int get storiesCompleted => _user?.storiesCompleted ?? 0;
  int get quizzesCompleted => _user?.quizzesCompleted ?? 0;
  bool get darkMode => _user?.darkMode ?? false;

  String? get _uid => _auth.currentUser?.uid;

  // ── Load profile from Firestore ──────────────────────────────
  Future<void> loadProfile() async {
    final uid = _uid;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _repo.getUser(uid);

      if (_user != null) {
        _displayName = _user!.displayName ?? _user!.name;
        _photoUrl = _user!.photoUrl;
        _bio = _user!.bio;
        _preferredLanguage = _user!.preferredLanguage;
      } else {
        _displayName = _auth.currentUser?.displayName;
        _photoUrl = _auth.currentUser?.photoURL;
      }

      // Load favorites & history in parallel
      final results = await Future.wait([
        _repo.getFavorites(uid),
        _repo.getHistory(uid),
      ]);
      _favorites = results[0] as List<UserFavorite>;
      _history = results[1] as List<UserHistory>;
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
