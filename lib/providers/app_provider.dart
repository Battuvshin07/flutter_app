import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';
import '../services/culture_service.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../models/quiz.dart';
import '../data/models/culture_model.dart';

/// Central state management provider per doc §2: "Provider state management"
class AppProvider with ChangeNotifier {
  int _selectedNavIndex = 0;
  bool _isLoading = false;
  final DataService _dataService = DataService();
  final CultureService _cultureService = CultureService();

  StreamSubscription<List<CultureModel>>? _culturesSub;
  List<CultureModel> _cultures = [];

  // Merged persons: local JSON + Firestore avatarUrl
  List<Person> _mergedPersons = [];

  int get selectedNavIndex => _selectedNavIndex;
  bool get isLoading => _isLoading;
  DataService get dataService => _dataService;

  List<Person> get persons =>
      _mergedPersons.isNotEmpty ? _mergedPersons : _dataService.persons;
  List<Event> get events => _dataService.events;
  List<Quiz> get quizzes => _dataService.quizzes;

  /// Cultures streamed from Firestore.
  List<CultureModel> get cultures => _cultures;

  AppProvider() {
    _initCulturesStream();
  }

  void _initCulturesStream() {
    _culturesSub = _cultureService.watchCultures().listen(
      (data) {
        _cultures = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('AppProvider cultures stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _culturesSub?.cancel();
    super.dispose();
  }

  void setSelectedNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dataService.loadAll();
      await _mergeFirestoreAvatars();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch avatarUrl from Firestore persons and merge into local Person list.
  Future<void> _mergeFirestoreAvatars() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('persons')
          .get()
          .timeout(const Duration(seconds: 10));

      // Build name → avatarUrl map from Firestore
      final avatarMap = <String, String>{};
      for (final doc in snap.docs) {
        final name = doc.data()['name'] as String?;
        final avatarUrl = doc.data()['avatarUrl'] as String?;
        if (name != null && avatarUrl != null && avatarUrl.isNotEmpty) {
          avatarMap[name] = avatarUrl;
        }
      }

      // Merge: update imageUrl on local Person if Firestore has avatarUrl
      _mergedPersons = _dataService.persons.map((p) {
        final firestoreUrl = avatarMap[p.name];
        if (firestoreUrl != null) {
          return p.copyWith(imageUrl: firestoreUrl);
        }
        return p;
      }).toList();
    } catch (e) {
      debugPrint('AppProvider._mergeFirestoreAvatars error: $e');
      // Fall back to local data without merging
      _mergedPersons = [];
    }
  }

  List<Event> getEventsForPerson(int personId) {
    return _dataService.getEventsForPerson(personId);
  }

  Person? getPersonById(int personId) {
    return _dataService.getPersonById(personId);
  }

  List<Person> searchPersons(String query) {
    return _dataService.searchPersons(query);
  }
}
