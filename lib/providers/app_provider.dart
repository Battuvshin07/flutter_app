import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../models/quiz.dart';

/// Central state management provider per doc §2: "Provider state management"
class AppProvider with ChangeNotifier {
  int _selectedNavIndex = 0;
  bool _isLoading = false;
  final DataService _dataService = DataService();

  int get selectedNavIndex => _selectedNavIndex;
  bool get isLoading => _isLoading;
  DataService get dataService => _dataService;

  List<Person> get persons => _dataService.persons;
  List<Event> get events => _dataService.events;
  List<Quiz> get quizzes => _dataService.quizzes;
  List<Map<String, dynamic>> get culture => _dataService.culture;

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
