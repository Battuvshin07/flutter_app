import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';

/// Authentication state provider.
/// Listens to Firebase Auth state and resolves the user's role.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();

  User? _user;
  String _role = 'user';
  bool _isLoading = true;
  String? _error;

  StreamSubscription<User?>? _authSub;

  AuthProvider() {
    _init();
  }

  // ── Getters ──────────────────────────────────────────────────
  User? get user => _user;
  String get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _role == 'admin' || _role == 'superAdmin';
  bool get isSuperAdmin => _role == 'superAdmin';
  String? get error => _error;

  // ── Init ─────────────────────────────────────────────────────
  void _init() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _user = user;

    if (user != null) {
      _isLoading = true;
      notifyListeners();

      try {
        _role = await _roleService
                .getCurrentUserRole()
                .timeout(const Duration(seconds: 8), onTimeout: () => 'user') ??
            'user';
      } catch (_) {
        _role = 'user';
      }
    } else {
      _role = 'user';
    }

    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // ── Auth actions ─────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUpWithEmailPassword(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    // Eagerly reset role BEFORE Firebase sign-out fires the stream
    // to prevent stale admin state leaking to the next login.
    _role = 'user';
    _user = null;
    _error = null;
    notifyListeners();

    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Force refresh role (e.g. after admin promotes via Cloud Function).
  Future<void> refreshRole() async {
    if (_user != null) {
      _role = await _roleService.getCurrentUserRole() ?? 'user';
      notifyListeners();
    }
  }

  // ── Error mapping ────────────────────────────────────────────
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Энэ имэйл хаяг бүртгэлтэй байна.';
      case 'invalid-email':
        return 'Имэйл хаяг буруу байна.';
      case 'weak-password':
        return 'Нууц үг хэт богино байна (8+ тэмдэгт).';
      case 'user-not-found':
        return 'Бүртгэлтэй хэрэглэгч олдсонгүй.';
      case 'wrong-password':
        return 'Нууц үг буруу байна.';
      case 'user-disabled':
        return 'Таны бүртгэл түр хаагдсан байна.';
      case 'too-many-requests':
        return 'Хэт олон оролдлого. Түр хүлээнэ үү.';
      case 'invalid-credential':
        return 'Имэйл эсвэл нууц үг буруу байна.';
      default:
        return 'Алдаа гарлаа ($code).';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
