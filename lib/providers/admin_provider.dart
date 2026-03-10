import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/admin_repository.dart';
import '../data/models/culture_model.dart';
import '../data/models/person_model.dart';
import '../data/models/person_detail_model.dart';
import '../data/models/quiz_model.dart';
import '../data/models/event_model.dart';
import '../data/models/story_model.dart';
import '../data/models/video_model.dart';

/// State management provider for all admin CRUD operations.
/// Uses ChangeNotifier (matching the project's existing Provider pattern).
class AdminProvider with ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ── Total users count ──
  int _totalUsers = 0;
  int get totalUsers => _totalUsers;

  bool _totalUsersLoaded = false;
  bool get totalUsersLoaded => _totalUsersLoaded;

  String? _totalUsersError;
  String? get totalUsersError => _totalUsersError;

  // ── Cultures ──
  List<CultureModel> _cultures = [];
  List<CultureModel> get cultures => _cultures;

  // ── Persons ──
  List<PersonModel> _persons = [];
  List<PersonModel> get persons => _persons;

  // ── Quizzes ──
  List<QuizModel> _quizzes = [];
  List<QuizModel> get quizzes => _quizzes;

  // ── Events ──
  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  // ── Stories ──
  List<StoryModel> _stories = [];
  List<StoryModel> get stories => _stories;

  // ── Videos ──
  List<VideoModel> _videos = [];
  List<VideoModel> get videos => _videos;

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

  bool _eventsLoaded = false;
  bool get eventsLoaded => _eventsLoaded;

  bool _storiesLoaded = false;
  bool get storiesLoaded => _storiesLoaded;

  bool _videosLoaded = false;
  bool get videosLoaded => _videosLoaded;

  /// True when all collection streams + user count have delivered at least once.
  bool get allStreamsLoaded =>
      _totalUsersLoaded &&
      _culturesLoaded &&
      _personsLoaded &&
      _quizzesLoaded &&
      _eventsLoaded &&
      _storiesLoaded &&
      _videosLoaded;

  /// True if any stream or the user count encountered an error.
  bool get hasStreamError => _totalUsersError != null;

  // ── Stream subscriptions ──
  StreamSubscription? _culturesSub;
  StreamSubscription? _personsSub;
  StreamSubscription? _quizzesSub;
  StreamSubscription? _eventsSub;
  StreamSubscription? _storiesSub;
  StreamSubscription? _videosSub;

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
    _videosSub = _repo.watchVideos().listen(
      (data) {
        _videos = data;
        _videosLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('videos stream error: $e');
        _videosLoaded = true;
        notifyListeners();
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TOTAL USERS
  // ══════════════════════════════════════════════════════════════

  Future<void> loadTotalUsers() async {
    try {
      _totalUsersError = null;
      _totalUsers = await _repo.getTotalUserCount();
      _totalUsersLoaded = true;
      notifyListeners();
    } catch (e) {
      _totalUsersError = e.toString();
      _totalUsersLoaded = true;
      debugPrint('Error loading total users: $e');
      notifyListeners();
    }
  }

  /// Refresh user count (streams auto-refresh via Firestore listeners).
  Future<void> refreshAll() async {
    _totalUsersLoaded = false;
    _totalUsersError = null;
    notifyListeners();
    await loadTotalUsers();
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

  /// Creates a person and returns the new Firestore document ID, or null on error.
  Future<String?> createPersonAndGetId(PersonModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final id = await _repo.createPerson(model);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
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
  //  VIDEOS
  // ══════════════════════════════════════════════════════════════

  Future<bool> createVideo(VideoModel model) async {
    return _safeExecute(() => _repo.createVideo(model));
  }

  Future<bool> updateVideo(VideoModel model) async {
    return _safeExecute(() => _repo.updateVideo(model));
  }

  Future<bool> deleteVideo(String id) async {
    return _safeExecute(() => _repo.deleteVideo(id));
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
    _eventsSub?.cancel();
    _storiesSub?.cancel();
    _videosSub?.cancel();
    super.dispose();
  }
}
