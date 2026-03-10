import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/video_model.dart';

/// Public-facing service for streaming published videos from Firestore.
///
/// Screens use this directly; the [AdminProvider] uses [AdminRepository]
/// for full CRUD (including unpublished docs).
class VideoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live stream of published videos ordered by [order] ascending.
  Stream<List<VideoModel>> watchVideos() {
    return _db
        .collection('videos')
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) {
      final results = <VideoModel>[];
      for (final doc in snap.docs) {
        try {
          results.add(VideoModel.fromFirestore(doc));
        } catch (e) {
          // skip malformed docs silently
        }
      }
      return results;
    });
  }

  /// One-shot fetch of all published videos.
  Future<List<VideoModel>> getVideos() async {
    final snap = await _db
        .collection('videos')
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => VideoModel.fromFirestore(d)).toList();
  }
}
