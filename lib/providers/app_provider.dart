import 'dart:async';
import 'package:flutter/material.dart';
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

  int get selectedNavIndex => _selectedNavIndex;
  bool get isLoading => _isLoading;
  DataService get dataService => _dataService;

  List<Person> get persons => _dataService.persons;
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
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
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
