import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/culture_model.dart';
import '../models/person_model.dart';
import '../models/person_detail_model.dart';
import '../models/quiz_model.dart';
import '../models/event_model.dart';
import '../models/story_model.dart';
import '../models/video_model.dart';

enum ProgressQuerySource {
  flatProgress,
  userProgressQuizzes,
  usersProgress,
}

class AdminProgressPage {
  final List<Map<String, dynamic>> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  final ProgressQuerySource source;

  const AdminProgressPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.source,
  });
}

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

  Future<String> createPerson(PersonModel model) async {
    final ref = await _db.collection('persons').add(model.toFirestore());
    return ref.id;
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

  Future<AdminProgressPage> getProgressPage({
    int limit = 40,
    ProgressQuerySource? source,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (source == ProgressQuerySource.flatProgress) {
      return _fetchFlatProgressPage(limit: limit, startAfter: startAfter);
    }
    if (source == ProgressQuerySource.userProgressQuizzes) {
      return _fetchCollectionGroupPage(
        limit: limit,
        startAfter: startAfter,
        collectionGroup: 'quizzes',
        source: ProgressQuerySource.userProgressQuizzes,
        pathMatcher: _isUserProgressQuizPath,
      );
    }
    if (source == ProgressQuerySource.usersProgress) {
      return _fetchCollectionGroupPage(
        limit: limit,
        startAfter: startAfter,
        collectionGroup: 'progress',
        source: ProgressQuerySource.usersProgress,
        pathMatcher: _isUsersProgressPath,
      );
    }

    final flatPage =
        await _fetchFlatProgressPage(limit: limit, startAfter: startAfter);
    if (flatPage.items.isNotEmpty) return flatPage;

    final userProgressPage = await _fetchCollectionGroupPage(
      limit: limit,
      startAfter: startAfter,
      collectionGroup: 'quizzes',
      source: ProgressQuerySource.userProgressQuizzes,
      pathMatcher: _isUserProgressQuizPath,
    );
    if (userProgressPage.items.isNotEmpty) return userProgressPage;

    return _fetchCollectionGroupPage(
      limit: limit,
      startAfter: startAfter,
      collectionGroup: 'progress',
      source: ProgressQuerySource.usersProgress,
      pathMatcher: _isUsersProgressPath,
    );
  }

  Future<List<Map<String, dynamic>>> getAllProgress({int limit = 200}) async {
    final page = await getProgressPage(limit: limit);
    return page.items;
  }

  Future<AdminProgressPage> _fetchFlatProgressPage({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('progress').orderBy('updatedAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snap = await query.limit(limit).get();
      return AdminProgressPage(
        items: snap.docs.map((d) => _toProgressMap(d)).toList(),
        cursor: snap.docs.isNotEmpty ? snap.docs.last : startAfter,
        hasMore: snap.docs.length == limit,
        source: ProgressQuerySource.flatProgress,
      );
    } on FirebaseException {
      Query<Map<String, dynamic>> fallback =
          _db.collection('progress').orderBy(FieldPath.documentId);
      if (startAfter != null) {
        fallback = fallback.startAfterDocument(startAfter);
      }
      final snap = await fallback.limit(limit).get();
      return AdminProgressPage(
        items: snap.docs.map((d) => _toProgressMap(d)).toList(),
        cursor: snap.docs.isNotEmpty ? snap.docs.last : startAfter,
        hasMore: snap.docs.length == limit,
        source: ProgressQuerySource.flatProgress,
      );
    }
  }

  Future<AdminProgressPage> _fetchCollectionGroupPage({
    required int limit,
    required String collectionGroup,
    required ProgressQuerySource source,
    required bool Function(String path) pathMatcher,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final results = <Map<String, dynamic>>[];
    var cursor = startAfter;
    var reachedEnd = false;
    final batchSize = (limit * 2).clamp(60, 200);

    // Filter by full path so top-level collections with same name are excluded.
    while (results.length < limit && !reachedEnd) {
      Query<Map<String, dynamic>> query = _db
          .collectionGroup(collectionGroup)
          .orderBy(FieldPath.documentId)
          .limit(batchSize);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        reachedEnd = true;
        break;
      }

      cursor = snap.docs.last;
      if (snap.docs.length < batchSize) {
        reachedEnd = true;
      }

      for (final doc in snap.docs) {
        if (!pathMatcher(doc.reference.path)) continue;
        results.add(_toProgressMap(doc));
        if (results.length >= limit) break;
      }
    }

    return AdminProgressPage(
      items: results,
      cursor: cursor,
      hasMore: !reachedEnd,
      source: source,
    );
  }

  bool _isUserProgressQuizPath(String path) {
    final segments = path.split('/');
    return segments.length >= 4 &&
        segments[0] == 'user_progress' &&
        segments[2] == 'quizzes';
  }

  bool _isUsersProgressPath(String path) {
    final segments = path.split('/');
    return segments.length >= 4 &&
        segments[0] == 'users' &&
        segments[2] == 'progress';
  }

  Map<String, dynamic> _toProgressMap(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final path = doc.reference.path;
    final data = doc.data();
    final segments = path.split('/');

    String? userId;
    if (_isUserProgressQuizPath(path) || _isUsersProgressPath(path)) {
      userId = segments[1];
    }

    return {
      'id': doc.id,
      'path': path,
      if (userId != null) 'userId': userId,
      ...data,
    };
  }

  /// Deletes a single progress record. Accepts either a flat `progress/{id}`
  /// doc or `user_progress/{userId}/quizzes/{quizId}`.
  Future<void> deleteProgress(String id, {String? userId, String? path}) async {
    if (path != null && path.isNotEmpty) {
      await _db.doc(path).delete();
      return;
    }

    if (userId != null) {
      await _db.doc('user_progress/$userId/quizzes/$id').delete();
      await _db.doc('users/$userId/progress/$id').delete();
    } else {
      await _db.collection('progress').doc(id).delete();
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  VIDEOS — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<VideoModel>> watchVideos() {
    return _db
        .collection('videos')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => _safeParse(snap, VideoModel.fromFirestore));
  }

  Future<void> createVideo(VideoModel model) async {
    await _db.collection('videos').add(model.toFirestore());
  }

  Future<void> updateVideo(VideoModel model) async {
    await _db.collection('videos').doc(model.id).update(model.toFirestore());
  }

  Future<void> deleteVideo(String id) async {
    await _db.collection('videos').doc(id).delete();
  }
}
