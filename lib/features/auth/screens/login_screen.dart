// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/aurora_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../profile/providers/user_profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Defaults to 'customer' so the non-Firebase dev fallback and the
      // "uid is somehow null" edge case still have a safe value to read
      // below, instead of needing a separate redirect path for them.
      String role = 'customer';
      if (FirebaseStatus.isInitialized) {
        final credential = await authRepository.login(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );

        // Pull the real profile (name/phone) from Firestore so the app
        // shows the actual logged-in user instead of demo data.
        final uid = credential.user?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final data = doc.data();

          // Enforce the admin's "Block Account" action — without this
          // check, a blocked customer's Firestore flag was purely
          // decorative and they could keep logging in and shopping
          // normally.
          if (data?['isBlocked'] == true) {
            await authRepository.logout();
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This account has been blocked. Please contact support.',
                ),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          // Read directly off the Firestore doc we already have in hand
          // rather than from userProfileProvider — its own listener
          // updates asynchronously and might not have the fresh role
          // in yet at this exact moment.
          role = ((data?['role'] as String?) ?? 'customer')
              .trim()
              .toLowerCase();

          ref
              .read(userProfileProvider.notifier)
              .update(
                name:
                    data?['fullName'] as String? ??
                    credential.user?.displayName ??
                    'User',
                email:
                    credential.user?.email ?? _identifierController.text.trim(),
                phone: data?['phone'] as String? ?? '',
                avatarUrl: data?['avatarUrl'] as String?,
                role: role,
              );
        }
      } else {
        // Dev fallback: Firebase not set up yet (see firebase/FIREBASE_SETUP.md).
        await Future.delayed(const Duration(milliseconds: 900));
      }
      if (!mounted) {
        return;
      }
      // Remember the "Remember me" choice. Firebase keeps the session
      // on the device by itself; the splash screen reads this flag at
      // the next app start and signs the user out if it was unticked.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      if (!mounted) {
        return;
      }

      // Staff accounts land on the Admin Dashboard first; customers go
      // straight to the store.
      if (role != 'customer') {
        context.go(AppRoutes.admin);
      } else {
        context.go(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(_friendlyAuthError(e.code))),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.lg,
              AppDimens.xl,
              AppDimens.lg,
              AppDimens.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFE8E5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                    )
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: AppDimens.lg),
                Text(
                      AppStrings.welcomeBack,
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 6),
                Text(
                  AppStrings.loginSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
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
                              label: AppStrings.email,
                              hint: 'you@example.com or 03XX-XXXXXXX',
                              controller: _identifierController,
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'This field is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimens.md),
                            AppTextField(
                              label: AppStrings.password,
                              hint: 'Enter your password',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimens.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: (v) => setState(
                                          () => _rememberMe = v ?? true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.rememberMe,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.forgotPassword),
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: AppTextStyles.link,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.md),
                            PrimaryButton(
                              label: AppStrings.login,
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: AppDimens.lg),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    AppStrings.orContinueWith,
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: AppDimens.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Google',
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: AppDimens.md),
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.apple_rounded,
                                    label: 'Apple',
                                    onTap: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 450.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                const SizedBox(height: AppDimens.xl),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      children: [
                        const TextSpan(text: AppStrings.dontHaveAccount),
                        TextSpan(
                          text: AppStrings.createAccount,
                          style: AppTextStyles.link.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(AppRoutes.register),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                const SizedBox(height: AppDimens.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textPrimary),
      label: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.border),
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }
}

/// Firebase Auth returns technical codes like "invalid-credential" — this
/// maps the common ones to messages a customer can actually act on,
/// instead of showing Firebase's raw internal wording.
String _friendlyAuthError(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password. Please try again.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    default:
      return 'Login failed. Please try again.';
  }
}
