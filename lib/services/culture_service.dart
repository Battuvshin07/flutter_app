import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/culture_model.dart';

/// Public-facing Firestore service for the `cultures` collection.
/// Used by [AppProvider] to stream culture data for the public screens.
class CultureService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real-time stream of all cultures, ordered by `order` field ascending.
  Stream<List<CultureModel>> watchCultures() {
    return _db
        .collection('cultures')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snap) {
      final results = <CultureModel>[];
      for (final doc in snap.docs) {
        try {
          results.add(CultureModel.fromFirestore(doc));
        } catch (e) {
          // Skip malformed docs silently
        }
      }
      return results;
    });
  }

  /// One-time fetch of all cultures.
  Future<List<CultureModel>> getCultures() async {
    final snap = await _db
        .collection('cultures')
        .orderBy('order', descending: false)
        .get();
    return snap.docs.map((d) => CultureModel.fromFirestore(d)).toList();
  }

  /// Fetch a single culture by Firestore document ID.
  Future<CultureModel?> getCultureById(String id) async {
    final doc = await _db.collection('cultures').doc(id).get();
    if (!doc.exists) return null;
    return CultureModel.fromFirestore(doc);
  }

  // ── Progress persistence ──────────────────────────────────────

  /// Loads culture completion progress for the current user.
  /// Returns a map of {cultureId: progress} where progress is 0.0 or 1.0.
  Future<Map<String, double>> loadProgress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('culture_progress')
          .get();
      return {
        for (final doc in snap.docs)
          doc.id: (doc.data()['completed'] == true) ? 1.0 : 0.0,
      };
    } catch (e) {
      return {};
    }
  }

  /// Marks a culture as completed for the current user.
  Future<void> markCompleted(String cultureId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('culture_progress')
        .doc(cultureId)
        .set({'completed': true, 'completedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
  }
}
