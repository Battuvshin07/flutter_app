import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Email verification screen shown after signup.
/// Prompts user to verify their email before accessing the app.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _canResend = true;
  int _resendCountdown = 0;
  Timer? _timer;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Auto-check every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final isVerified = await _authService.checkEmailVerified();
      if (isVerified && mounted) {
        // Email verified! Navigate to app
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      // Silent fail for auto-check
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _errorMsg = null;
      _canResend = false;
      _resendCountdown = 60;
    });

    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Баталгаажуулах имэйл илгээгдлээ'),
            backgroundColor: AppTheme.accentGold,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Start countdown
      Timer.periodic(const Duration(seconds: 1), (timer) {
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
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _canResend = true;
          _resendCountdown = 0;
          _errorMsg = e.message ?? 'Имэйл илгээхэд алдаа гарлаа';
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    // AuthGate will redirect to login
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
                    Icons.email_outlined,
                    size: 48,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Имэйл баталгаажуулах',
                  style: AppTheme.h2.copyWith(color: AppTheme.accentGold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Info text
                ClipRRect(
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
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTheme.body.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: 'Таны '),
                                TextSpan(
                                  text: email,
                                  style: const TextStyle(
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' хаяг руу баталгаажуулах имэйл илгээгдлээ.\n\n'
                                      'Имэйлээ шалгаад линк дээр дарна уу.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isChecking)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accentGold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Шалгаж байна...',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.crimson.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: AppTheme.crimson.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.crimson, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.crimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Resend button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _canResend ? _resendVerificationEmail : null,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: _canResend ? Colors.white : AppTheme.textSecondary,
                    ),
                    label: Text(
                      _canResend
                          ? 'Дахин илгээх'
                          : 'Дахин илгээх ($_resendCountdown)',
                      style: TextStyle(
                        color:
                            _canResend ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canResend
                          ? AppTheme.accentGold
                          : AppTheme.surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Manual check button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _checkEmailVerified,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Шалгах'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out
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
}
