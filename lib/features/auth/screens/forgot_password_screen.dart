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

/// Step 1 of the Forgot Password flow (Section 5 in the PRD):
/// Enter email/phone -> Send OTP -> Verify OTP -> New password -> Login.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (FirebaseStatus.isInitialized) {
        await authRepository.sendPasswordResetEmail(_identifierController.text.trim());
      } else {
        // Dev fallback: Firebase not set up yet (see firebase/FIREBASE_SETUP.md).
        await Future.delayed(const Duration(milliseconds: 700));
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Could not send reset email')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        colors: const [Color(0xFF3E9DFF), Color(0xFF2E7FDB)],
        child: SafeArea(
          child: Padding(
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
                      ? 'We\u2019ve sent a verification code to ${_identifierController.text}. Enter it on the next screen to continue.'
                      : 'Enter the email or phone number linked to your account and we\u2019ll send you a code to reset your password.',
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
                            label: 'Email or Phone',
                            hint: 'you@example.com or 03XX-XXXXXXX',
                            controller: _identifierController,
                            prefixIcon: Icons.alternate_email_rounded,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'This field is required' : null,
                          ),
                          const SizedBox(height: AppDimens.xl),
                          PrimaryButton(
                            label: 'Send Code',
                            isLoading: _isLoading,
                            onPressed: _handleSend,
                          ),
                        ] else ...[
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 30),
                          ),
                          const SizedBox(height: AppDimens.lg),
                          PrimaryButton(
                            label: 'Enter Verification Code',
                            onPressed: () {
                              // TODO(phase-2): navigate to OTP verification screen
                            },
                          ),
                          const SizedBox(height: AppDimens.md),
                          PrimaryButton(
                            label: 'Back to Login',
                            outlined: true,
                            onPressed: () => context.pop(),
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
