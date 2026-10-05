import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

void showChangeEmailDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _ChangeEmailDialog());
}

class _NeedsVerification implements Exception {
  final String email;
  const _NeedsVerification(this.email);
}

/// Changing the e-mail is also changing the login identity, so it is done
/// the safe way: the person proves they know the password, then Firebase
/// sends a verification link to the NEW address. The e-mail only changes
/// once that link is tapped (the profile is brought in line the next time
/// the app starts — see splash_screen.dart).
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog();

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Your password is incorrect.';
        case 'email-already-in-use':
          return 'That e-mail already belongs to another account.';
        case 'invalid-email':
          return 'Please enter a valid e-mail address.';
        case 'requires-recent-login':
          return 'For security, please log out, log in again, and retry.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'operation-not-allowed':
          return 'E-mail change by verification is not enabled for this Firebase project.';
      }
    }
    debugPrint('Change email failed: $e');
    final code = e is FirebaseAuthException ? ' (${e.code})' : '';
    return 'Could not start the e-mail change$code. Please try again.';
  }

  /// Asks Firebase to e-mail a confirmation link to the NEW address.
  /// Firebase can refuse this while the CURRENT address is unverified —
  /// and this app never verified anyone's address at sign-up. In that case
  /// the current address gets a verification link first.
  Future<void> _requestChange(User user, String newEmail, String current) async {
    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'unverified-email') rethrow;
    }
    await user.reload();
    final fresh = FirebaseAuth.instance.currentUser ?? user;
    if (fresh.emailVerified) {
      await fresh.verifyBeforeUpdateEmail(newEmail);
      return;
    }
    await fresh.sendEmailVerification();
    throw _NeedsVerification(current);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final newEmail = _email.text.trim();
    try {
      final user = FirebaseAuth.instance.currentUser;
      final current = user?.email;
      if (user == null || current == null) throw FirebaseAuthException(code: 'no-current-user');
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: current, password: _password.text));
      await _requestChange(user, newEmail, current);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Verification link sent to $newEmail. Check your Spam/Junk folder too. '
            'Your e-mail changes only after you tap the link. '
            '(No mail? That address may already belong to another account.)',
          ),
        ),
      );
    } on _NeedsVerification catch (n) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 9),
          content: Text(
            'Your current e-mail (${n.email}) isn\u2019t verified yet. We sent a verification link to it. '
            'Tap that link (check Spam too), then try Change Email again.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Change Email', style: AppTextStyles.h4)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'We will send a verification link to the new address. Your e-mail changes only after you tap it.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'New Email',
                  hint: 'you@example.com',
                  controller: _email,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter the new e-mail';
                    if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid e-mail';
                    if (v.trim().toLowerCase() == FirebaseAuth.instance.currentUser?.email?.toLowerCase()) {
                      return 'This is already your e-mail';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Current Password',
                  hint: 'To confirm it is you',
                  controller: _password,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppDimens.lg),
                PrimaryButton(label: 'Send Verification Link', isLoading: _saving, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
