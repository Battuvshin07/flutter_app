import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../models/map_data.dart';
import '../models/quiz.dart';

/// Firestore CRUD service for all content collections.
///
/// - Authenticated users: read
/// - Admin users: create / update / delete
/// - User progress: per-user subcollection
class ContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════
  //  PERSONS
  // ═══════════════════════════════════════

  /// Stream all persons, ordered by person_id.
  Stream<List<Person>> personsStream() {
    return _db
        .collection('persons')
        .orderBy('person_id')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Person.fromMap(d.data())).toList());
  }

  /// Get all persons once.
  Future<List<Person>> getPersons() async {
    final snap = await _db.collection('persons').orderBy('person_id').get();
    return snap.docs.map((d) => Person.fromMap(d.data())).toList();
  }

  /// Admin: create a person.
  Future<void> createPerson(Person person) async {
    final docId = 'person_${person.personId}';
    await _db.doc('persons/$docId').set({
      ...person.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: update a person.
  Future<void> updatePerson(Person person) async {
    final docId = 'person_${person.personId}';
    await _db.doc('persons/$docId').update({
      ...person.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: delete a person.
  Future<void> deletePerson(int personId) async {
    await _db.doc('persons/person_$personId').delete();
  }

  // ═══════════════════════════════════════
  //  EVENTS
  // ═══════════════════════════════════════

  Stream<List<Event>> eventsStream() {
    return _db
        .collection('events')
        .orderBy('event_id')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromMap(d.data())).toList());
  }

  Future<List<Event>> getEvents() async {
    final snap = await _db.collection('events').orderBy('event_id').get();
    return snap.docs.map((d) => Event.fromMap(d.data())).toList();
  }

  Future<void> createEvent(Event event) async {
    final docId = 'event_${event.eventId}';
    await _db.doc('events/$docId').set({
      ...event.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEvent(Event event) async {
    final docId = 'event_${event.eventId}';
    await _db.doc('events/$docId').update({
      ...event.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent(int eventId) async {
    await _db.doc('events/event_$eventId').delete();
  }

  // ═══════════════════════════════════════
  //  MAPS
  // ═══════════════════════════════════════

  Stream<List<MapData>> mapsStream() {
    return _db.collection('maps').orderBy('map_id').snapshots().map(
        (snap) => snap.docs.map((d) => MapData.fromMap(d.data())).toList());
  }

  Future<List<MapData>> getMaps() async {
    final snap = await _db.collection('maps').orderBy('map_id').get();
    return snap.docs.map((d) => MapData.fromMap(d.data())).toList();
  }

  Future<void> createMap(MapData mapData) async {
    final docId = 'map_${mapData.mapId}';
    await _db.doc('maps/$docId').set({
      ...mapData.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMap(MapData mapData) async {
    final docId = 'map_${mapData.mapId}';
    await _db.doc('maps/$docId').update({
      ...mapData.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMap(int mapId) async {
    await _db.doc('maps/map_$mapId').delete();
  }

  // ═══════════════════════════════════════
  //  QUIZZES
  // ═══════════════════════════════════════

  Stream<List<Quiz>> quizzesStream() {
    return _db
        .collection('quizzes')
        .orderBy('quiz_id')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Quiz.fromMap(d.data())).toList());
  }

  Future<List<Quiz>> getQuizzes() async {
    final snap = await _db.collection('quizzes').orderBy('quiz_id').get();
    return snap.docs.map((d) => Quiz.fromMap(d.data())).toList();
  }

  Future<void> createQuiz(Quiz quiz) async {
    final docId = 'quiz_${quiz.quizId}';
    await _db.doc('quizzes/$docId').set({
      ...quiz.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuiz(Quiz quiz) async {
    final docId = 'quiz_${quiz.quizId}';
    await _db.doc('quizzes/$docId').update({
      ...quiz.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuiz(int quizId) async {
    await _db.doc('quizzes/quiz_$quizId').delete();
  }

  // ═══════════════════════════════════════
  //  CULTURE
  // ═══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> cultureStream() {
    return _db
        .collection('culture')
        .orderBy('culture_id')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<List<Map<String, dynamic>>> getCulture() async {
    final snap = await _db.collection('culture').orderBy('culture_id').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> createCulture(Map<String, dynamic> data) async {
    final docId = 'culture_${data['id'] ?? data['culture_id']}';
    await _db.doc('culture/$docId').set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCulture(String docId, Map<String, dynamic> data) async {
    await _db.doc('culture/$docId').update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCulture(String docId) async {
    await _db.doc('culture/$docId').delete();
  }

  // ═══════════════════════════════════════
  //  USER PROGRESS (per-user subcollection)
  // ═══════════════════════════════════════

  /// Save quiz attempt result for the current user.
  Future<void> saveQuizProgress({
    required String uid,
    required int quizId,
    required int score,
    required bool completed,
    required int selectedAnswer,
  }) async {
    final ref = _db.doc('user_progress/$uid/quizzes/quiz_$quizId');
    final existing = await ref.get();

    await ref.set({
      'quiz_id': quizId,
      'score': score,
      'completed': completed,
      'selectedAnswer': selectedAnswer,
      'attempts':
          (existing.exists ? (existing.data()?['attempts'] ?? 0) : 0) + 1,
      'lastAttemptAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get all quiz progress for a user.
  Future<List<Map<String, dynamic>>> getUserQuizProgress(String uid) async {
    final snap = await _db.collection('user_progress/$uid/quizzes').get();
    return snap.docs.map((d) => {'docId': d.id, ...d.data()}).toList();
  }

  /// Save / update the user's aggregated progress summary.
  Future<void> updateProgressSummary({
    required String uid,
    required Map<String, dynamic> summary,
  }) async {
    await _db.doc('user_progress/$uid/summary/stats').set({
      ...summary,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════
  //  FAVORITES (per-user subcollection)
  // ═══════════════════════════════════════

  Future<void> addFavorite({
    required String uid,
    required String contentType,
    required String contentId,
    required String title,
  }) async {
    await _db.doc('favorites/$uid/items/$contentId').set({
      'contentType': contentType,
      'contentId': contentId,
      'title': title,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite({
    required String uid,
    required String contentId,
  }) async {
    await _db.doc('favorites/$uid/items/$contentId').delete();
  }

  Stream<List<Map<String, dynamic>>> favoritesStream(String uid) {
    return _db
        .collection('favorites/$uid/items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'docId': d.id, ...d.data()}).toList());
  }
}
