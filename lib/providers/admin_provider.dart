import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/admin_repository.dart';
import '../data/models/culture_model.dart';
import '../data/models/person_model.dart';
import '../data/models/person_detail_model.dart';
import '../data/models/quiz_model.dart';
import '../data/models/content_model.dart';
import '../data/models/event_model.dart';
import '../data/models/story_model.dart';

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

  // ── Quizzes ──
  List<QuizModel> _quizzes = [];
  List<QuizModel> get quizzes => _quizzes;

  // ── Contents ──
  List<ContentModel> _contents = [];
  List<ContentModel> get contents => _contents;

  // ── Events ──
  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  // ── Stories ──
  List<StoryModel> _stories = [];
  List<StoryModel> get stories => _stories;

  // ── Progress (flat list for admin read) ──
  List<Map<String, dynamic>> _progress = [];
  List<Map<String, dynamic>> get progress => _progress;

  // ── Loading / Error ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Per-collection stream initialized flags ──
  bool _culturesLoaded = false;
  bool get culturesLoaded => _culturesLoaded;

  bool _personsLoaded = false;
  bool get personsLoaded => _personsLoaded;

  bool _quizzesLoaded = false;
  bool get quizzesLoaded => _quizzesLoaded;

  bool _contentsLoaded = false;
  bool get contentsLoaded => _contentsLoaded;

  bool _eventsLoaded = false;
  bool get eventsLoaded => _eventsLoaded;

  bool _storiesLoaded = false;
  bool get storiesLoaded => _storiesLoaded;

  // ── Stream subscriptions ──
  StreamSubscription? _culturesSub;
  StreamSubscription? _personsSub;
  StreamSubscription? _quizzesSub;
  StreamSubscription? _contentsSub;
  StreamSubscription? _eventsSub;
  StreamSubscription? _storiesSub;

  AdminProvider() {
    _initStreams();
    loadTotalUsers();
  }

  void _initStreams() {
    _culturesSub = _repo.watchCultures().listen(
      (data) {
        _cultures = data;
        _culturesLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('cultures stream error: $e');
        _culturesLoaded = true;
        notifyListeners();
      },
    );
    _personsSub = _repo.watchPersons().listen(
      (data) {
        _persons = data;
        _personsLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('persons stream error: $e');
        _personsLoaded = true;
        notifyListeners();
      },
    );
    _quizzesSub = _repo.watchQuizzes().listen(
      (data) {
        _quizzes = data;
        _quizzesLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('quizzes stream error: $e');
        _quizzesLoaded = true;
        notifyListeners();
      },
    );
    _contentsSub = _repo.watchContents().listen(
      (data) {
        _contents = data;
        _contentsLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('contents stream error: $e');
        _contentsLoaded = true;
        notifyListeners();
      },
    );
    _eventsSub = _repo.watchEvents().listen(
      (data) {
        _events = data;
        _eventsLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('events stream error: $e');
        _eventsLoaded = true;
        notifyListeners();
      },
    );
    _storiesSub = _repo.watchStories().listen(
      (data) {
        _stories = data;
        _storiesLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('stories stream error: $e');
        _storiesLoaded = true;
        notifyListeners();
      },
    );
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
  //  CONTENTS
  // ══════════════════════════════════════════════════════════════

  Future<bool> createContent(ContentModel model) async {
    return _safeExecute(() => _repo.createContent(model));
  }

  Future<bool> updateContent(ContentModel model) async {
    return _safeExecute(() => _repo.updateContent(model));
  }

  Future<bool> deleteContent(String id) async {
    return _safeExecute(() => _repo.deleteContent(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  EVENTS
  // ══════════════════════════════════════════════════════════════

  Future<bool> createEvent(EventModel model) async {
    return _safeExecute(() => _repo.createEvent(model));
  }

  Future<bool> updateEvent(EventModel model) async {
    return _safeExecute(() => _repo.updateEvent(model));
  }

  Future<bool> deleteEvent(String id) async {
    return _safeExecute(() => _repo.deleteEvent(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  STORIES
  // ══════════════════════════════════════════════════════════════

  Future<bool> createStory(StoryModel model) async {
    return _safeExecute(() => _repo.createStory(model));
  }

  Future<bool> updateStory(StoryModel model) async {
    return _safeExecute(() => _repo.updateStory(model));
  }

  Future<bool> deleteStory(String id) async {
    return _safeExecute(() => _repo.deleteStory(id));
  }

  // ══════════════════════════════════════════════════════════════
  //  PROGRESS (read-only + admin reset)
  // ══════════════════════════════════════════════════════════════

  Future<void> loadProgress() async {
    _isLoading = true;
    notifyListeners();
    try {
      _progress = await _repo.getAllProgress();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProgress(String id, {String? userId}) async {
    return _safeExecute(() => _repo.deleteProgress(id, userId: userId));
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
    _quizzesSub?.cancel();
    _contentsSub?.cancel();
    _eventsSub?.cancel();
    _storiesSub?.cancel();
    super.dispose();
  }
}
