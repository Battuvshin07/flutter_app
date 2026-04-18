import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/otp_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// OTP verification screen.
/// Shows 6-digit code input after signup for email verification.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _otpService = OtpService();
  final _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isSending = false;
  bool _canResend = true;
  int _resendCountdown = 0;
  int _expiryCountdown = 300; // 5 minutes in seconds
  String? _errorMsg;
  String? _successMsg;
  Timer? _resendTimer;
  Timer? _expiryTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _setupShakeAnimation();
    _sendInitialCode();
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _sendInitialCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isSending = true);

    final result = await _otpService.sendVerificationCode(
      email: user.email!,
      userId: user.uid,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (result.success) {
          _startExpiryTimer();
          _startResendCooldown();
        } else {
          _errorMsg = result.message;
        }
      });
    }
  }

  void _startExpiryTimer() {
    _expiryCountdown = 300; // Reset to 5 minutes
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_expiryCountdown > 0) {
          _expiryCountdown--;
        } else {
          timer.cancel();
          _errorMsg = 'Код хүчингүй боллоо. Шинэ код авна уу.';
        }
      });
    });
  }

  void _startResendCooldown() {
    _canResend = false;
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() {
      _isSending = true;
      _errorMsg = null;
      _successMsg = null;
    });

    final result = await _otpService.sendVerificationCode(
      email: user.email!,
      userId: user.uid,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (result.success) {
          _successMsg = 'Шинэ код илгээгдлээ';
          _clearOtpFields();
          _startExpiryTimer();
          _startResendCooldown();
        } else {
          _errorMsg = result.message;
        }
      });
    }
  }

  void _clearOtpFields() {
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onOtpChanged(int index, String value) {
    // Clear messages on input
    if (_errorMsg != null || _successMsg != null) {
      setState(() {
        _errorMsg = null;
        _successMsg = null;
      });
    }

    if (value.length == 1 && index < 5) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits entered
    if (_getOtpCode().length == 6) {
      _verifyCode();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getOtpCode();
    if (code.length != 6) {
      setState(() => _errorMsg = '6 оронтой код оруулна уу');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _errorMsg = 'Хэрэглэгч олдсонгүй');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    final result = await _otpService.verifyCode(
      email: user.email!,
      code: code,
      userId: user.uid,
    );

    if (mounted) {
      if (result.success) {
        // Success! Refresh auth provider and navigate to home
        setState(() {
          _isLoading = false;
          _successMsg = 'Имэйл баталгаажлаа!';
        });

        // Refresh the email verification status in AuthProvider
        if (mounted) {
          await context
              .read<app_auth.AuthProvider>()
              .refreshEmailVerificationStatus();
        }

        // Short delay to show success message
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        // Error - shake the input fields
        _shakeController.forward().then((_) => _shakeController.reset());
        setState(() {
          _isLoading = false;
          _errorMsg = result.message;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                _buildIcon(),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Имэйл баталгаажуулах',
                  style: AppTheme.h2.copyWith(color: AppTheme.accentGold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Info card
                _buildInfoCard(email),
                const SizedBox(height: 32),

                // OTP Input
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: _buildOtpInput(),
                ),
                const SizedBox(height: 16),

                // Expiry timer
                if (_expiryCountdown > 0 && _expiryCountdown < 300)
                  Text(
                    'Код хүчинтэй: ${_formatTime(_expiryCountdown)}',
                    style: AppTheme.caption.copyWith(
                      color: _expiryCountdown < 60
                          ? AppTheme.crimson
                          : AppTheme.textSecondary,
                    ),
                  ),
                const SizedBox(height: 24),

                // Error/Success messages
                if (_errorMsg != null) _buildErrorMessage(),
                if (_successMsg != null) _buildSuccessMessage(),
                const SizedBox(height: 16),

                // Verify button
                _buildVerifyButton(),
                const SizedBox(height: 12),

                // Resend button
                _buildResendButton(),
                const SizedBox(height: 24),

                // Sign out link
                TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Буцаж нэвтрэх',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
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
      child: _isSending
          ? const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.accentGold,
                ),
              ),
            )
          : const Icon(
              Icons.pin_outlined,
              size: 48,
              color: AppTheme.accentGold,
            ),
    );
  }

  Widget _buildInfoCard(String email) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '6 оронтой баталгаажуулах код '),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' хаяг руу илгээгдлээ.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 6,
            right: index == 5 ? 0 : 6,
          ),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyPressed(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: AppTheme.h2.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 24,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide:
                      const BorderSide(color: AppTheme.accentGold, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: AppTheme.crimson),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) => _onOtpChanged(index, value),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.crimson.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.crimson, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMsg!,
              style: AppTheme.caption.copyWith(color: AppTheme.crimson),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.xpGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.xpGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.xpGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMsg!,
              style: AppTheme.caption.copyWith(color: AppTheme.xpGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          disabledBackgroundColor: AppTheme.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Баталгаажуулах',
                style: AppTheme.button.copyWith(color: AppTheme.background),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _canResend && !_isSending ? _resendCode : null,
        icon: Icon(
          Icons.refresh_rounded,
          size: 20,
          color: _canResend ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
        label: Text(
          _canResend ? 'Дахин илгээх' : 'Дахин илгээх ($_resendCountdown)',
          style: TextStyle(
            color: _canResend ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(
            color: _canResend ? AppTheme.cardBorder : AppTheme.divider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}
