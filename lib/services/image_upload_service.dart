import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable service for picking images and uploading to Firebase Storage.
class ImageUploadService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Pick an image from gallery or camera.
  /// Returns the image bytes or null if cancelled.
  static Future<Uint8List?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 80,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      if (picked == null) return null;
      return await picked.readAsBytes();
    } catch (e) {
      debugPrint('ImageUploadService.pickImage error: $e');
      return null;
    }
  }

  /// Upload image bytes to Firebase Storage at the given [path].
  /// Returns the download URL or null on failure.
  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String storagePath,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('ImageUploadService.uploadImage error: $e');
      return null;
    }
  }

  /// Pick an image and upload it in one step.
  /// Returns the download URL or null if cancelled or failed.
  static Future<String?> pickAndUpload({
    required String storagePath,
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 80,
  }) async {
    final bytes = await pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (bytes == null) return null;
    return uploadImage(bytes: bytes, storagePath: storagePath);
  }
}
