import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/admin_repository.dart';
import '../data/models/culture_model.dart';
import '../data/models/person_model.dart';
import '../data/models/person_detail_model.dart';
import '../data/models/family_tree_model.dart';
import '../data/models/quiz_model.dart';

/// State management provider for all admin CRUD operations.
/// Uses ChangeNotifier (matching the project's existing Provider pattern).
class AdminProvider with ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ── Total users count ──
  int _totalUsers = 0;
  int get totalUsers => _totalUsers;

  // ── Cultures ──
  List<CultureModel> _cultures = [];
  List<CultureModel> get cultures => _cultures;

  // ── Persons ──
  List<PersonModel> _persons = [];
  List<PersonModel> get persons => _persons;

  // ── Family Trees ──
  List<FamilyTreeModel> _familyTrees = [];
  List<FamilyTreeModel> get familyTrees => _familyTrees;

  // ── Quizzes ──
  List<QuizModel> _quizzes = [];
  List<QuizModel> get quizzes => _quizzes;

  // ── Loading / Error ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Stream subscriptions ──
  StreamSubscription? _culturesSub;
  StreamSubscription? _personsSub;
  StreamSubscription? _familyTreesSub;
  StreamSubscription? _quizzesSub;

  AdminProvider() {
    _initStreams();
    loadTotalUsers();
  }

  void _initStreams() {
    _culturesSub = _repo.watchCultures().listen((data) {
      _cultures = data;
      notifyListeners();
    });
    _personsSub = _repo.watchPersons().listen((data) {
      _persons = data;
      notifyListeners();
    });
    _familyTreesSub = _repo.watchFamilyTrees().listen((data) {
      _familyTrees = data;
      notifyListeners();
    });
    _quizzesSub = _repo.watchQuizzes().listen((data) {
      _quizzes = data;
      notifyListeners();
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  TOTAL USERS
  // ══════════════════════════════════════════════════════════════

  Future<void> loadTotalUsers() async {
    try {
      _totalUsers = await _repo.getTotalUserCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading total users: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  CULTURES
  // ══════════════════════════════════════════════════════════════

  Future<bool> createCulture(CultureModel model) async {
    return _safeExecute(() => _repo.createCulture(model));
  }

  Future<bool> updateCulture(CultureModel model) async {
    return _safeExecute(() => _repo.updateCulture(model));
  }

  Future<bool> deleteCulture(String id) async {
    return _safeExecute(() => _repo.deleteCulture(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  PERSONS
  // ══════════════════════════════════════════════════════════════

  Future<bool> createPerson(PersonModel model) async {
    return _safeExecute(() => _repo.createPerson(model));
  }

  Future<bool> updatePerson(PersonModel model) async {
    return _safeExecute(() => _repo.updatePerson(model));
  }

  Future<bool> deletePerson(String id) async {
    return _safeExecute(() => _repo.deletePerson(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  PERSON DETAILS
  // ══════════════════════════════════════════════════════════════

  Future<PersonDetailModel?> getPersonDetail(String personId) async {
    try {
      return await _repo.getPersonDetail(personId);
    } catch (e) {
      debugPrint('Error loading person detail: $e');
      return null;
    }
  }

  Future<bool> savePersonDetail(PersonDetailModel model) async {
    return _safeExecute(() => _repo.savePersonDetail(model));
  }

  Future<bool> deletePersonDetail(String personId) async {
    return _safeExecute(() => _repo.deletePersonDetail(personId));
  }

  // ══════════════════════════════════════════════════════════════
  //  FAMILY TREES
  // ══════════════════════════════════════════════════════════════

  Future<bool> createFamilyTree(FamilyTreeModel model) async {
    return _safeExecute(() => _repo.createFamilyTree(model));
  }

  Future<bool> updateFamilyTree(FamilyTreeModel model) async {
    return _safeExecute(() => _repo.updateFamilyTree(model));
  }

  Future<bool> deleteFamilyTree(String id) async {
    return _safeExecute(() => _repo.deleteFamilyTree(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  QUIZZES
  // ══════════════════════════════════════════════════════════════

  Future<bool> createQuiz(QuizModel model) async {
    return _safeExecute(() => _repo.createQuiz(model));
  }

  Future<bool> updateQuiz(QuizModel model) async {
    return _safeExecute(() => _repo.updateQuiz(model));
  }

  Future<bool> deleteQuiz(String id) async {
    return _safeExecute(() => _repo.deleteQuiz(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════

  Future<bool> _safeExecute(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _culturesSub?.cancel();
    _personsSub?.cancel();
    _familyTreesSub?.cancel();
    _quizzesSub?.cancel();
    super.dispose();
  }
}
