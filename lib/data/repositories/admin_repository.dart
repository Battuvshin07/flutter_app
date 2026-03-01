import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/culture_model.dart';
import '../models/person_model.dart';
import '../models/person_detail_model.dart';
import '../models/family_tree_model.dart';
import '../models/quiz_model.dart';

/// Repository for all admin CRUD operations against Cloud Firestore.
///
/// Uses direct Firestore count aggregation (AggregateQuery) for total users
/// to avoid reading all user documents. This is efficient and cost-effective
/// for small-to-medium projects (<100K users). For very large scale, consider
/// a Cloud Function that maintains stats/global.totalUsers on user
/// onCreate/onDelete triggers.
class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        .map((snap) =>
            snap.docs.map((d) => CultureModel.fromFirestore(d)).toList());
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
        .map((snap) =>
            snap.docs.map((d) => PersonModel.fromFirestore(d)).toList());
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
  //  FAMILY TREE — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<FamilyTreeModel>> watchFamilyTrees() {
    return _db
        .collection('family_tree')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FamilyTreeModel.fromFirestore(d)).toList());
  }

  Future<List<FamilyTreeModel>> getFamilyTrees({String? searchQuery}) async {
    Query query =
        _db.collection('family_tree').orderBy('updatedAt', descending: true);
    final snap = await query.get();
    var list = snap.docs.map((d) => FamilyTreeModel.fromFirestore(d)).toList();
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> createFamilyTree(FamilyTreeModel model) async {
    await _db.collection('family_tree').add(model.toFirestore());
  }

  Future<void> updateFamilyTree(FamilyTreeModel model) async {
    await _db
        .collection('family_tree')
        .doc(model.id)
        .update(model.toFirestore());
  }

  Future<void> deleteFamilyTree(String id) async {
    await _db.collection('family_tree').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  QUIZZES — CRUD
  // ══════════════════════════════════════════════════════════════

  Stream<List<QuizModel>> watchQuizzes() {
    return _db
        .collection('quizzes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => QuizModel.fromFirestore(d)).toList());
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
}
