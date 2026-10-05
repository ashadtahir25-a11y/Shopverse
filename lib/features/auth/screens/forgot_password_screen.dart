// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/aurora_background.dart';
import '../../../core/widgets/glass_card.dart';

/// Forgot Password: enter the account e-mail -> Firebase e-mails a reset
/// LINK -> the person opens it, picks a new password -> logs in.
///
/// (The old screen promised a "verification code" and had an "Enter
/// Verification Code" button that did nothing. Firebase sends a link, not a
/// code, so the screen now says exactly what really happens.)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _resendSeconds = 60;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailRegex = RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,}$');
  Timer? _timer;
  int _cooldown = 0;
  bool _isLoading = false;
  bool _sent = false;
  String _sentTo = '';

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account was found with that email.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Could not send the reset email (${e.code}). Please try again.';
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handleSend() async {
    if (_isLoading) return;
    if (!_sent && !_formKey.currentState!.validate()) return;
    final email = _sent ? _sentTo : _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      if (FirebaseStatus.isInitialized) {
        await authRepository.sendPasswordResetEmail(email);
      } else {
        // Dev fallback: Firebase not set up yet (see firebase/FIREBASE_SETUP.md).
        await Future.delayed(const Duration(milliseconds: 700));
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
        _sentTo = email;
      });
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast(_friendly(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        colors: const [Color(0xFF3E9DFF), Color(0xFF2E7FDB)],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const SizedBox(height: AppDimens.lg),
                Text(
                  _sent ? 'Check your inbox' : 'Reset your password',
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _sent
                      ? 'If an account exists for $_sentTo, we\u2019ve sent a password reset link to it. '
                          'Open the link, choose a new password, then log in.'
                      : 'Enter the email linked to your account and we\u2019ll send you a link to reset your password.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: AppDimens.xl),
                GlassCard(
                  opacity: 0.94,
                  blurSigma: 22,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_sent) ...[
                          AppTextField(
                            label: 'Email',
                            hint: 'you@example.com',
                            controller: _emailController,
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter your email';
                              if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimens.xl),
                          PrimaryButton(label: 'Send Reset Link', isLoading: _isLoading, onPressed: _handleSend),
                        ] else ...[
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                              child: Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 30),
                            ),
                          ),
                          const SizedBox(height: AppDimens.md),
                          Text(
                            'Can\u2019t see it? Look in your Spam/Junk folder. The email can take a minute or two to arrive.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
                          ),
                          const SizedBox(height: AppDimens.lg),
                          PrimaryButton(label: 'Back to Login', onPressed: () => context.pop()),
                          const SizedBox(height: AppDimens.md),
                          PrimaryButton(
                            label: _cooldown > 0 ? 'Resend link in ${_cooldown}s' : 'Resend Link',
                            outlined: true,
                            isLoading: _isLoading,
                            onPressed: _cooldown > 0 ? null : _handleSend,
                          ),
                          const SizedBox(height: AppDimens.sm),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() {
                                _sent = false;
                                _timer?.cancel();
                                _cooldown = 0;
                              }),
                              child: Text('Use a different email', style: AppTextStyles.link),
                            ),
                          ),
                        ],
                      ],
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
