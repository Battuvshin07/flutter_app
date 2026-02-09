import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../models/map_data.dart';
import '../models/quiz.dart';

/// Offline-first data service that loads all data from local JSON assets.
/// Per doc: "мэдээллийг локал өгөгдлийн санд хадгалж, оффлайн дэмжлэгтэй ажилладаг"
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Person> _persons = [];
  List<Event> _events = [];
  List<MapData> _maps = [];
  List<Quiz> _quizzes = [];
  List<Map<String, dynamic>> _culture = [];
  bool _isLoaded = false;

  List<Person> get persons => _persons;
  List<Event> get events => _events;
  List<MapData> get maps => _maps;
  List<Quiz> get quizzes => _quizzes;
  List<Map<String, dynamic>> get culture => _culture;
  bool get isLoaded => _isLoaded;

  Future<void> loadAll() async {
    if (_isLoaded) return;

    await Future.wait([
      _loadPersons(),
      _loadEvents(),
      _loadMaps(),
      _loadQuizzes(),
      _loadCulture(),
    ]);

    _isLoaded = true;
  }

  Future<void> _loadPersons() async {
    final jsonStr = await rootBundle.loadString('assets/data/persons.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _persons = jsonList.map((j) => Person.fromMap(j)).toList();
  }

  Future<void> _loadEvents() async {
    final jsonStr = await rootBundle.loadString('assets/data/events.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _events = jsonList.map((j) => Event.fromMap(j)).toList();
  }

  Future<void> _loadMaps() async {
    final jsonStr = await rootBundle.loadString('assets/data/maps.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _maps = jsonList.map((j) => MapData.fromMap(j)).toList();
  }

  Future<void> _loadQuizzes() async {
    final jsonStr = await rootBundle.loadString('assets/data/quizzes.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _quizzes = jsonList.map((j) => Quiz.fromMap(j)).toList();
  }

  Future<void> _loadCulture() async {
    final jsonStr = await rootBundle.loadString('assets/data/culture.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _culture = jsonList.cast<Map<String, dynamic>>();
  }

  List<Event> getEventsForPerson(int personId) {
    return _events.where((e) => e.personId == personId).toList();
  }

  Person? getPersonById(int personId) {
    try {
      return _persons.firstWhere((p) => p.personId == personId);
    } catch (_) {
      return null;
    }
  }

  List<Person> searchPersons(String query) {
    final q = query.toLowerCase();
    return _persons.where((p) => p.name.toLowerCase().contains(q)).toList();
  }
}
