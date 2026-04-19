import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/otp_service.dart';
import '../theme/app_theme.dart';

enum _LoginOtpStep {
  requestOtp,
  verifyOtp,
}

/// OTP login screen.
///
/// Step 1: enter email and request OTP.
/// Step 2: verify OTP and sign in using Firebase custom token.
class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  final _otpService = OtpService();
  final _authService = AuthService();

  _LoginOtpStep _step = _LoginOtpStep.requestOtp;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMsg;
  String? _infoMsg;

  String? _loginEmail;
  DateTime? _expiresAt;

  Timer? _resendTimer;
  Timer? _expiryTimer;
  int _resendCountdown = 0;
  int _expiryCountdown = 0;

  bool get _isBusy => _isSending || _isVerifying;
  bool get _canResend => _resendCountdown <= 0 && !_isBusy;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _resetToEmailStep() {
    _resendTimer?.cancel();
    _expiryTimer?.cancel();

    final previousEmail = _loginEmail;

    setState(() {
      _step = _LoginOtpStep.requestOtp;
      _errorMsg = null;
      _infoMsg = null;
      _codeCtrl.clear();
      _resendCountdown = 0;
      _expiryCountdown = 0;
      _expiresAt = null;
      if (previousEmail != null) {
        _emailCtrl.text = previousEmail;
      }
      _loginEmail = null;
    });
  }

  int _secondsUntilExpiry() {
    if (_expiresAt == null) {
      return 5 * 60;
    }

    final diff = _expiresAt!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    _resendCountdown = seconds > 0 ? seconds : 60;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCountdown <= 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _resendCountdown--;
      });
    });
  }

  void _startExpiryCountdown(DateTime? expiresAt) {
    _expiryTimer?.cancel();

    final now = DateTime.now();
    final fallbackExpiry = now.add(const Duration(minutes: 5));
    _expiresAt = (expiresAt != null && expiresAt.isAfter(now))
        ? expiresAt
        : fallbackExpiry;

    _expiryCountdown = _secondsUntilExpiry();

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final secondsLeft = _secondsUntilExpiry();
      setState(() {
        _expiryCountdown = secondsLeft;

        if (_step == _LoginOtpStep.verifyOtp && secondsLeft == 0) {
          _infoMsg = null;
          _errorMsg ??= 'Кодын хугацаа дууссан байна. Дахин код илгээнэ үү.';
        }
      });

      if (secondsLeft == 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _requestOtp({bool isResend = false}) async {
    if (!isResend && !_emailFormKey.currentState!.validate()) {
      return;
    }

    final sourceEmail =
        isResend ? (_loginEmail ?? _emailCtrl.text) : _emailCtrl.text;
    final email = sourceEmail.trim().toLowerCase();

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMsg = 'Зөв имэйл хаяг оруулна уу';
        _infoMsg = null;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMsg = null;
      _infoMsg = null;
    });

    final result = await _otpService.sendLoginOtp(email: email);

    if (!mounted) return;

    if (result.success) {
      _startResendCooldown(result.resendAfterSeconds);
      _startExpiryCountdown(result.expiresAt);

      setState(() {
        _isSending = false;
        _step = _LoginOtpStep.verifyOtp;
        _loginEmail = email;
        _emailCtrl.text = email;
        _codeCtrl.clear();
        _infoMsg = isResend ? 'Шинэ код илгээгдлээ.' : result.message;
      });
      return;
    }

    setState(() {
      _isSending = false;
      _errorMsg = result.message;
    });
  }

  Future<void> _verifyOtpAndSignIn() async {
    if (!_codeFormKey.currentState!.validate()) {
      return;
    }

    if (_expiryCountdown <= 0) {
      setState(() {
        _errorMsg = 'Кодын хугацаа дууссан байна. Дахин код илгээнэ үү.';
        _infoMsg = null;
      });
      return;
    }

    final email = _loginEmail;
    if (email == null || !_isValidEmail(email)) {
      setState(() {
        _errorMsg = 'Имэйл мэдээлэл дутуу байна. Дахин оролдоно уу.';
        _infoMsg = null;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMsg = null;
      _infoMsg = null;
    });

    final verifyResult = await _otpService.verifyLoginOtp(
      email: email,
      code: _codeCtrl.text.trim(),
    );

    if (!mounted) return;

    if (!verifyResult.success) {
      setState(() {
        _isVerifying = false;
        _errorMsg = verifyResult.message;
      });
      return;
    }

    final customToken = verifyResult.customToken;
    if (customToken == null || customToken.isEmpty) {
      setState(() {
        _isVerifying = false;
        _errorMsg = 'Нэвтрэх токен үүссэнгүй. Дахин оролдоно уу.';
      });
      return;
    }

    try {
      await _authService.signInWithCustomToken(customToken);

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _errorMsg = null;
        _infoMsg = 'Амжилттай нэвтэрлээ.';
      });

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMsg = _mapAuthError(e.code);
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMsg = 'Нэвтрэхэд алдаа гарлаа: ${e.toString()}';
      });
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-custom-token':
        return 'Нэвтрэх токен буруу байна.';
      case 'custom-token-mismatch':
        return 'Токен тохирохгүй байна. Дахин оролдоно уу.';
      case 'user-disabled':
        return 'Таны бүртгэл түр хаагдсан байна.';
      case 'user-not-found':
        return 'Бүртгэлтэй хэрэглэгч олдсонгүй.';
      case 'network-request-failed':
        return 'Сүлжээний алдаа гарлаа. Дахин оролдоно уу.';
      default:
        return 'Нэвтрэхэд алдаа гарлаа ($code).';
    }
  }

  String _subtitleText() {
    switch (_step) {
      case _LoginOtpStep.requestOtp:
        return 'Бүртгэлтэй имэйл хаягаа оруулж нэвтрэх код авна уу.';
      case _LoginOtpStep.verifyOtp:
        return 'Имэйлээр ирсэн 6 оронтой кодоор нэвтэрнэ.';
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.background,
      prefixIcon: Icon(icon, color: AppTheme.accentGold, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.accentGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.crimson),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.crimson),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildMessageBox({
    required String message,
    required Color borderColor,
    required Color textColor,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.caption.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
            decoration: _inputDecoration(
              hintText: 'Имэйл хаяг',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return 'Имэйл оруулна уу';
              }
              if (!_isValidEmail(email)) {
                return 'Зөв имэйл хаяг оруулна уу';
              }
              return null;
            },
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _buildMessageBox(
              message: _errorMsg!,
              icon: Icons.error_outline,
              textColor: AppTheme.crimson,
              borderColor: AppTheme.crimson.withValues(alpha: 0.3),
              backgroundColor: AppTheme.crimson.withValues(alpha: 0.1),
            ),
          ],
          if (_infoMsg != null) ...[
            const SizedBox(height: 12),
            _buildMessageBox(
              message: _infoMsg!,
              icon: Icons.info_outline,
              textColor: AppTheme.accentGold,
              borderColor: AppTheme.accentGold.withValues(alpha: 0.35),
              backgroundColor: AppTheme.accentGold.withValues(alpha: 0.1),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBusy ? null : () => _requestOtp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 0,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Код илгээх',
                      style: AppTheme.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alternate_email_rounded,
                  color: AppTheme.accentGold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loginEmail ?? '',
                    style: AppTheme.captionBold.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isBusy ? null : _resetToEmailStep,
                  child: Text(
                    'Өөрчлөх',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.accentGold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            style: AppTheme.h2.copyWith(
              color: AppTheme.textPrimary,
              letterSpacing: 2,
            ),
            decoration: _inputDecoration(
              hintText: '6 оронтой OTP код',
              icon: Icons.pin_outlined,
            ).copyWith(counterText: ''),
            validator: (value) {
              final code = value?.trim() ?? '';
              if (code.isEmpty) {
                return 'OTP код оруулна уу';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                return 'OTP код 6 оронтой байх ёстой';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Код хүчинтэй: ${_formatTime(_expiryCountdown)}',
            style: AppTheme.caption.copyWith(
              color: _expiryCountdown <= 60
                  ? AppTheme.crimson
                  : AppTheme.textSecondary,
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            _buildMessageBox(
              message: _errorMsg!,
              icon: Icons.error_outline,
              textColor: AppTheme.crimson,
              borderColor: AppTheme.crimson.withValues(alpha: 0.3),
              backgroundColor: AppTheme.crimson.withValues(alpha: 0.1),
            ),
          ],
          if (_infoMsg != null) ...[
            const SizedBox(height: 12),
            _buildMessageBox(
              message: _infoMsg!,
              icon: Icons.info_outline,
              textColor: AppTheme.accentGold,
              borderColor: AppTheme.accentGold.withValues(alpha: 0.35),
              backgroundColor: AppTheme.accentGold.withValues(alpha: 0.1),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBusy ? null : _verifyOtpAndSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Нэвтрэх',
                      style: AppTheme.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _canResend ? () => _requestOtp(isResend: true) : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _canResend
                      ? AppTheme.accentGold.withValues(alpha: 0.6)
                      : AppTheme.cardBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _canResend
                    ? 'Код дахин илгээх'
                    : 'Дахин илгээх боломжтой: ${_formatTime(_resendCountdown)}',
                style: AppTheme.captionBold.copyWith(
                  color:
                      _canResend ? AppTheme.accentGold : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: _step == _LoginOtpStep.requestOtp
              ? _buildRequestStep()
              : _buildVerifyStep(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.password_rounded,
                  size: 48,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'OTP кодоор нэвтрэх',
                style: AppTheme.h2.copyWith(color: AppTheme.accentGold),
              ),
              const SizedBox(height: 12),
              Text(
                _subtitleText(),
                style: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildStepCard(),
            ],
          ),
        ),
      ),
    );
  }
}
