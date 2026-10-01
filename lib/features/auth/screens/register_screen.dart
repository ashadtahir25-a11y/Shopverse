import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/aurora_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../profile/providers/user_profile_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (FirebaseStatus.isInitialized) {
        await authRepository.register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Dev fallback: Firebase not set up yet (see firebase/FIREBASE_SETUP.md).
        await Future.delayed(const Duration(milliseconds: 900));
      }

      // Reflect the real entered details in the app's profile state
      // immediately (instead of the old hard-coded "Ayesha Khan" demo user).
      ref
          .read(userProfileProvider.notifier)
          .update(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        colors: const [Color(0xFF16C79A), Color(0xFF0FA37F)],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.lg,
              AppDimens.md,
              AppDimens.lg,
              AppDimens.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
                ),
                const SizedBox(height: AppDimens.lg),
                Text(
                      AppStrings.registerTitle,
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 6),
                Text(
                  AppStrings.registerSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: AppDimens.xl),

                GlassCard(
                      opacity: 0.94,
                      blurSigma: 22,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: AppStrings.fullName,
                              hint: 'e.g. Ayesha Khan',
                              controller: _nameController,
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  (v == null || v.trim().length < 3)
                                  ? 'Enter your full name'
                                  : null,
                            ),
                            const SizedBox(height: AppDimens.md),
                            AppTextField(
                              label: AppStrings.email,
                              hint: 'you@example.com',
                              controller: _emailController,
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!_emailRegex.hasMatch(v)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimens.md),
                            AppTextField(
                              label: AppStrings.phone,
                              hint: '03XX-XXXXXXX',
                              controller: _phoneController,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.trim().length < 10) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimens.md),
                            AppTextField(
                              label: AppStrings.password,
                              hint: 'At least 8 characters',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'Minimum 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimens.md),
                            AppTextField(
                              label: AppStrings.confirmPassword,
                              hint: 'Re-enter your password',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimens.xl),
                            PrimaryButton(
                              label: AppStrings.createAccount,
                              isLoading: _isLoading,
                              onPressed: _handleRegister,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 450.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                const SizedBox(height: AppDimens.lg),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      children: [
                        const TextSpan(text: AppStrings.alreadyHaveAccount),
                        TextSpan(
                          text: AppStrings.login,
                          style: AppTextStyles.link.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
