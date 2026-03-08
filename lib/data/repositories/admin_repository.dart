import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/culture_model.dart';
import '../models/person_model.dart';
import '../models/person_detail_model.dart';
import '../models/quiz_model.dart';
import '../models/event_model.dart';
import '../models/story_model.dart';

/// Repository for all admin CRUD operations against Cloud Firestore.
///
/// Uses direct Firestore count aggregation (AggregateQuery) for total users
/// to avoid reading all user documents. This is efficient and cost-effective
/// for small-to-medium projects (<100K users). For very large scale, consider
/// a Cloud Function that maintains stats/global.totalUsers on user
/// onCreate/onDelete triggers.
class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Safely map Firestore docs, skipping any that fail to parse.
  List<T> _safeParse<T>(
    QuerySnapshot snap,
    T Function(DocumentSnapshot) fromFirestore,
  ) {
    final results = <T>[];
    for (final doc in snap.docs) {
      try {
        results.add(fromFirestore(doc));
      } catch (e) {
        debugPrint('⚠ Skipping bad doc ${doc.id}: $e');
      }
    }
    return results;
  }

  // ══════════════════════════════════════════════════════════════
  //  USERS — count only
  // ══════════════════════════════════════════════════════════════

  /// Returns total user count using Firestore count() aggregation.
  /// This does NOT read all documents — it's a single aggregation query.
  Future<int> getTotalUserCount() async {
    final snapshot = await _db.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  // ══════════════════════════════════════════════════════════════
  //  CULTURES — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<CultureModel>> watchCultures() {
    return _db
        .collection('cultures')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => _safeParse(snap, CultureModel.fromFirestore));
  }

  Future<List<CultureModel>> getCultures({String? searchQuery}) async {
    Query query =
        _db.collection('cultures').orderBy('updatedAt', descending: true);
    final snap = await query.get();
    var list = snap.docs.map((d) => CultureModel.fromFirestore(d)).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> createCulture(CultureModel model) async {
    await _db.collection('cultures').add(model.toFirestore());
  }

  Future<void> updateCulture(CultureModel model) async {
    await _db.collection('cultures').doc(model.id).update(model.toFirestore());
  }

  Future<void> deleteCulture(String id) async {
    await _db.collection('cultures').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  PERSONS — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<PersonModel>> watchPersons() {
    return _db
        .collection('persons')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => _safeParse(snap, PersonModel.fromFirestore));
  }

  Future<List<PersonModel>> getPersons({String? searchQuery}) async {
    Query query =
        _db.collection('persons').orderBy('updatedAt', descending: true);
    final snap = await query.get();
    var list = snap.docs.map((d) => PersonModel.fromFirestore(d)).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> createPerson(PersonModel model) async {
    await _db.collection('persons').add(model.toFirestore());
  }

  Future<void> updatePerson(PersonModel model) async {
    await _db.collection('persons').doc(model.id).update(model.toFirestore());
  }

  Future<void> deletePerson(String id) async {
    // Also delete person_details doc if exists
    await _db.collection('person_details').doc(id).delete();
    await _db.collection('persons').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  PERSON DETAILS — CRUD (1:1 with persons)
  // ══════════════════════════════════════════════════════════════

  Future<PersonDetailModel?> getPersonDetail(String personId) async {
    final doc = await _db.collection('person_details').doc(personId).get();
    if (!doc.exists) return null;
    return PersonDetailModel.fromFirestore(doc);
  }

  Future<void> savePersonDetail(PersonDetailModel model) async {
    await _db
        .collection('person_details')
        .doc(model.id)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deletePersonDetail(String personId) async {
    await _db.collection('person_details').doc(personId).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  QUIZZES — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<QuizModel>> watchQuizzes() {
    return _db
        .collection('quizzes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => _safeParse(snap, QuizModel.fromFirestore));
  }

  Future<List<QuizModel>> getQuizzes({String? searchQuery}) async {
    Query query =
        _db.collection('quizzes').orderBy('updatedAt', descending: true);
    final snap = await query.get();
    var list = snap.docs.map((d) => QuizModel.fromFirestore(d)).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((qz) => qz.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> createQuiz(QuizModel model) async {
    await _db.collection('quizzes').add(model.toFirestore());
  }

  Future<void> updateQuiz(QuizModel model) async {
    await _db.collection('quizzes').doc(model.id).update(model.toFirestore());
  }

  Future<void> deleteQuiz(String id) async {
    await _db.collection('quizzes').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  EVENTS — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<EventModel>> watchEvents() {
    return _db
        .collection('events')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => _safeParse(snap, EventModel.fromFirestore));
  }

  Future<List<EventModel>> getEvents({String? searchQuery}) async {
    final snap = await _db
        .collection('events')
        .orderBy('updatedAt', descending: true)
        .get();
    var list = snap.docs.map((d) => EventModel.fromFirestore(d)).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) => e.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> createEvent(EventModel model) async {
    await _db.collection('events').add(model.toFirestore());
  }

  Future<void> updateEvent(EventModel model) async {
    await _db.collection('events').doc(model.id).update(model.toFirestore());
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  STORIES — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<StoryModel>> watchStories() {
    return _db
        .collection('stories')
        .orderBy('order')
        .snapshots()
        .map((snap) => _safeParse(snap, StoryModel.fromFirestore));
  }

  Future<List<StoryModel>> getStories({String? searchQuery}) async {
    final snap = await _db.collection('stories').orderBy('order').get();
    var list = snap.docs.map((d) => StoryModel.fromFirestore(d)).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((s) => s.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> createStory(StoryModel model) async {
    await _db.collection('stories').add(model.toFirestore());
  }

  Future<void> updateStory(StoryModel model) async {
    await _db.collection('stories').doc(model.id).update(model.toFirestore());
  }

  Future<void> deleteStory(String id) async {
    await _db.collection('stories').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  PROGRESS — Read-only admin view
  // ══════════════════════════════════════════════════════════════

  /// Returns a flat list of all progress docs across all users.
  /// Reads `user_progress/{uid}/quizzes` subcollections for each user.
  /// For a simpler admin view, we also support a top-level `progress`
  /// collection if present.
  Future<List<Map<String, dynamic>>> getAllProgress() async {
    // Try flat `progress` collection first
    final flat = await _db
        .collection('progress')
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .get();
    if (flat.docs.isNotEmpty) {
      return flat.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }
    // Fallback: read user_progress per-user subcollections
    final usersSnap = await _db.collection('user_progress').get();
    final results = <Map<String, dynamic>>[];
    for (final userDoc in usersSnap.docs) {
      final quizzesSnap = await userDoc.reference.collection('quizzes').get();
      for (final qDoc in quizzesSnap.docs) {
        results.add({'userId': userDoc.id, 'id': qDoc.id, ...qDoc.data()});
      }
    }
    return results;
  }

  /// Deletes a single progress record. Accepts either a flat `progress/{id}`
  /// doc or `user_progress/{userId}/quizzes/{quizId}`.
  Future<void> deleteProgress(String id, {String? userId}) async {
    if (userId != null) {
      await _db.doc('user_progress/$userId/quizzes/$id').delete();
    } else {
      await _db.collection('progress').doc(id).delete();
    }
  }
}
