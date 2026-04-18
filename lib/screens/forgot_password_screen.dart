import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Forgot password screen - allows users to reset their password via email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await _authService.resetPassword(_emailCtrl.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Энэ имэйл хаягтай хэрэглэгч олдсонгүй';
      } else if (e.code == 'invalid-email') {
        message = 'Буруу имэйл хаяг';
      } else if (e.code == 'too-many-requests') {
        message = 'Хэт олон оролдлого хийлээ. Түр хүлээгээд дахин оролдоно уу';
      } else {
        message = e.message ?? 'Алдаа гарлаа';
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Алдаа гарлаа: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
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
                  Icons.lock_reset_rounded,
                  size: 48,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Нууц үг сэргээх',
                style: AppTheme.h2.copyWith(color: AppTheme.accentGold),
              ),
              const SizedBox(height: 12),

              if (!_emailSent) ...[
                // Instruction text
                Text(
                  'Бүртгэлтэй имэйл хаягаа оруулна уу.\nТанд нууц үг солих линк илгээх болно.',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Form
                ClipRRect(
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Имэйл хаяг',
                                hintStyle: AppTheme.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppTheme.background,
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: AppTheme.accentGold, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide: const BorderSide(
                                      color: AppTheme.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide: const BorderSide(
                                      color: AppTheme.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide: const BorderSide(
                                      color: AppTheme.accentGold, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide:
                                      const BorderSide(color: AppTheme.crimson),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Имэйл оруулна уу';
                                }
                                if (!v.contains('@')) {
                                  return 'Зөв имэйл оруулна уу';
                                }
                                return null;
                              },
                            ),

                            // Error message
                            if (_errorMsg != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.crimson.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(
                                    color:
                                        AppTheme.crimson.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppTheme.crimson, size: 16),
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
                            ],
                            const SizedBox(height: 20),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendResetEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Илгээх',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Success message
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppTheme.accentGold,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Имэйл илгээгдлээ!',
                            style: AppTheme.sectionTitle.copyWith(
                              color: AppTheme.accentGold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                  text: _emailCtrl.text.trim(),
                                  style: const TextStyle(
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' хаяг руу нууц үг солих линк илгээгдлээ.\n\n'
                                      'Имэйлээ шалгаад заавар дагана уу.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Back to login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Буцах'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
