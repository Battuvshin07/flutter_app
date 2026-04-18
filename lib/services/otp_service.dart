import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// OTP verification service.
/// Calls Firebase Cloud Functions to send and verify OTP codes.
class OtpService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Send verification code to user's email.
  /// Returns success status and message.
  Future<OtpResult> sendVerificationCode({
    required String email,
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendVerificationCode');
      final result = await callable.call({
        'email': email,
        'userId': userId,
      });

      final data = result.data as Map<String, dynamic>;
      return OtpResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Код илгээгдлээ',
        expiresAt: data['expiresAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['expiresAt'])
            : null,
      );
    } on FirebaseFunctionsException catch (e) {
      return OtpResult(
        success: false,
        message: _mapFunctionError(e.code),
      );
    } catch (e) {
      return OtpResult(
        success: false,
        message: 'Код илгээхэд алдаа гарлаа: ${e.toString()}',
      );
    }
  }

  /// Verify the OTP code entered by user.
  /// Returns success status and message.
  Future<OtpResult> verifyCode({
    required String email,
    required String code,
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyCode');
      final result = await callable.call({
        'email': email,
        'code': code,
        'userId': userId,
      });

      final data = result.data as Map<String, dynamic>;
      return OtpResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Баталгаажлаа',
      );
    } on FirebaseFunctionsException catch (e) {
      return OtpResult(
        success: false,
        message: _mapFunctionError(e.code),
      );
    } catch (e) {
      return OtpResult(
        success: false,
        message: 'Код шалгахад алдаа гарлаа: ${e.toString()}',
      );
    }
  }

  /// Check if user's email is already verified via OTP.
  /// Checks the Firestore user document for emailVerified field.
  Future<bool> isEmailVerifiedViaOtp(String userId) async {
    try {
      final doc = await _db.doc('users/$userId').get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['emailVerified'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get remaining cooldown time for resend (in seconds).
  /// Returns 0 if can resend immediately.
  Future<int> getResendCooldown(String email) async {
    try {
      final query = await _db
          .collection('email_verifications')
          .where('email', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return 0;

      final doc = query.docs.first;
      final lastSentAt = doc.data()['createdAt'] as Timestamp?;
      if (lastSentAt == null) return 0;

      final elapsed = DateTime.now().difference(lastSentAt.toDate()).inSeconds;
      final cooldown = 60 - elapsed; // 60 second cooldown
      return cooldown > 0 ? cooldown : 0;
    } catch (e) {
      return 0; // Allow resend on error
    }
  }

  String _mapFunctionError(String code) {
    switch (code) {
      case 'invalid-argument':
        return 'Буруу мэдээлэл оруулсан байна.';
      case 'not-found':
        return 'Баталгаажуулах код олдсонгүй.';
      case 'permission-denied':
        return 'Хандах эрхгүй байна.';
      case 'resource-exhausted':
        return 'Хэт олон оролдлого. Түр хүлээнэ үү.';
      case 'failed-precondition':
        return 'Код хүчингүй болсон байна.';
      case 'deadline-exceeded':
        return 'Хугацаа хэтэрсэн байна. Дахин оролдоно уу.';
      case 'unauthenticated':
        return 'Нэвтрэх шаардлагатай.';
      default:
        return 'Алдаа гарлаа ($code).';
    }
  }
}

/// Result model for OTP operations.
class OtpResult {
  final bool success;
  final String message;
  final DateTime? expiresAt;

  OtpResult({
    required this.success,
    required this.message,
    this.expiresAt,
  });
}
