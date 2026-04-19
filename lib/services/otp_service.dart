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
    return _callOtpFunction(
      functionName: 'sendVerificationCode',
      payload: {
        'email': email,
        'userId': userId,
      },
      fallbackSuccessMessage: 'Код илгээгдлээ',
      fallbackErrorMessage: 'Код илгээхэд алдаа гарлаа',
    );
  }

  /// Verify the OTP code entered by user.
  /// Returns success status and message.
  Future<OtpResult> verifyCode({
    required String email,
    required String code,
    required String userId,
  }) async {
    return _callOtpFunction(
      functionName: 'verifyCode',
      payload: {
        'email': email,
        'code': code,
        'userId': userId,
      },
      fallbackSuccessMessage: 'Баталгаажлаа',
      fallbackErrorMessage: 'Код шалгахад алдаа гарлаа',
    );
  }

  /// Send login OTP to email.
  Future<OtpResult> sendLoginOtp({
    required String email,
  }) async {
    return _callOtpFunction(
      functionName: 'sendLoginOtp',
      payload: {
        'email': email,
      },
      fallbackSuccessMessage: 'Хэрэв бүртгэлтэй имэйл бол код илгээгдэнэ.',
      fallbackErrorMessage: 'Нэвтрэх код илгээхэд алдаа гарлаа',
    );
  }

  /// Verify login OTP and receive Firebase custom token.
  Future<OtpResult> verifyLoginOtp({
    required String email,
    required String code,
  }) async {
    return _callOtpFunction(
      functionName: 'verifyLoginOtp',
      payload: {
        'email': email,
        'code': code,
      },
      fallbackSuccessMessage: 'Код баталгаажлаа',
      fallbackErrorMessage: 'Нэвтрэх код шалгахад алдаа гарлаа',
    );
  }

  /// Send forgot-password OTP to email.
  Future<OtpResult> sendForgotPasswordOtp({
    required String email,
  }) async {
    return _callOtpFunction(
      functionName: 'sendForgotPasswordOtp',
      payload: {
        'email': email,
      },
      fallbackSuccessMessage: 'Хэрэв бүртгэлтэй имэйл бол код илгээгдэнэ.',
      fallbackErrorMessage: 'Нууц үг сэргээх код илгээхэд алдаа гарлаа',
    );
  }

  /// Verify forgot-password OTP and receive short-lived otpProof.
  Future<OtpResult> verifyForgotPasswordOtp({
    required String email,
    required String code,
  }) async {
    return _callOtpFunction(
      functionName: 'verifyForgotPasswordOtp',
      payload: {
        'email': email,
        'code': code,
      },
      fallbackSuccessMessage: 'Код баталгаажлаа',
      fallbackErrorMessage: 'Сэргээх код шалгахад алдаа гарлаа',
    );
  }

  /// Complete forgot-password flow using issued otpProof.
  Future<OtpResult> completeForgotPasswordWithOtp({
    required String email,
    required String otpProof,
    required String newPassword,
  }) async {
    return _callOtpFunction(
      functionName: 'completeForgotPasswordWithOtp',
      payload: {
        'email': email,
        'otpProof': otpProof,
        'newPassword': newPassword,
      },
      fallbackSuccessMessage: 'Нууц үг амжилттай шинэчлэгдлээ.',
      fallbackErrorMessage: 'Нууц үг сэргээхэд алдаа гарлаа',
    );
  }

  /// Send change-password OTP for authenticated user.
  Future<OtpResult> sendChangePasswordOtp({
    required String email,
    required String userId,
  }) async {
    return _callOtpFunction(
      functionName: 'sendChangePasswordOtp',
      payload: {
        'email': email,
        'userId': userId,
      },
      fallbackSuccessMessage: 'Код илгээгдлээ',
      fallbackErrorMessage: 'Нууц үг солих код илгээхэд алдаа гарлаа',
    );
  }

  /// Verify change-password OTP and receive short-lived otpProof.
  Future<OtpResult> verifyChangePasswordOtp({
    required String email,
    required String userId,
    required String code,
  }) async {
    return _callOtpFunction(
      functionName: 'verifyChangePasswordOtp',
      payload: {
        'email': email,
        'userId': userId,
        'code': code,
      },
      fallbackSuccessMessage: 'Код баталгаажлаа',
      fallbackErrorMessage: 'Нууц үг солих код шалгахад алдаа гарлаа',
    );
  }

  /// Complete change-password flow using issued otpProof.
  Future<OtpResult> completeChangePasswordWithOtp({
    required String userId,
    required String otpProof,
    required String newPassword,
  }) async {
    return _callOtpFunction(
      functionName: 'completeChangePasswordWithOtp',
      payload: {
        'userId': userId,
        'otpProof': otpProof,
        'newPassword': newPassword,
      },
      fallbackSuccessMessage: 'Нууц үг амжилттай шинэчлэгдлээ.',
      fallbackErrorMessage: 'Нууц үг солиход алдаа гарлаа',
    );
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

  Future<OtpResult> _callOtpFunction({
    required String functionName,
    required Map<String, dynamic> payload,
    required String fallbackSuccessMessage,
    required String fallbackErrorMessage,
  }) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(payload);
      final rawData = result.data;

      if (rawData is Map<String, dynamic>) {
        return _parseOtpResult(
          rawData,
          fallbackSuccessMessage: fallbackSuccessMessage,
        );
      }

      if (rawData is Map) {
        return _parseOtpResult(
          Map<String, dynamic>.from(rawData),
          fallbackSuccessMessage: fallbackSuccessMessage,
        );
      }

      return OtpResult(
        success: false,
        message: fallbackErrorMessage,
      );
    } on FirebaseFunctionsException catch (e) {
      return OtpResult(
        success: false,
        message: _mapFunctionError(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return OtpResult(
        success: false,
        message: '$fallbackErrorMessage: ${e.toString()}',
      );
    }
  }

  OtpResult _parseOtpResult(
    Map<String, dynamic> data, {
    required String fallbackSuccessMessage,
  }) {
    final success = data['success'] == true;
    final errorCode = _readString(data['errorCode']);
    final rawMessage = _readString(data['message']);

    final message = rawMessage ??
        (!success && errorCode != null
            ? _mapFunctionError(errorCode)
            : fallbackSuccessMessage);

    return OtpResult(
      success: success,
      message: message,
      expiresAt: _parseEpochDateTime(data['expiresAt']),
      otpProof: _readString(data['otpProof']),
      customToken: _readString(data['customToken']),
      resendAfterSeconds: _parseResendAfterSeconds(data),
      errorCode: errorCode,
      proofExpiresAt: _parseEpochDateTime(data['proofExpiresAt']),
    );
  }

  int _parseResendAfterSeconds(Map<String, dynamic> data) {
    final raw = data.containsKey('cooldownSeconds')
        ? data['cooldownSeconds']
        : data['resendAfterSeconds'];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  DateTime? _parseEpochDateTime(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    if (value is String) {
      final millis = int.tryParse(value);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }

    return null;
  }

  String? _readString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
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
  final String? otpProof;
  final String? customToken;
  final int resendAfterSeconds;
  final String? errorCode;
  final DateTime? proofExpiresAt;

  OtpResult({
    required this.success,
    required this.message,
    this.expiresAt,
    this.otpProof,
    this.customToken,
    this.resendAfterSeconds = 0,
    this.errorCode,
    this.proofExpiresAt,
  });
}
