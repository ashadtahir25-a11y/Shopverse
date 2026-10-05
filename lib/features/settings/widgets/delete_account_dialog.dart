// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_flow.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../profile/providers/user_profile_provider.dart';

void showDeleteAccountDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _DeleteAccountDialog());
}

/// Real account deletion (it used to be a button that only closed a dialog).
///
/// Order matters: the password is checked FIRST, so nothing is touched if it
/// is wrong. Then the data this person is allowed to remove is deleted, the
/// profile is blanked, and only at the very end the login itself is deleted.
///
/// Orders, reviews, returns and support tickets are NOT removed: the
/// security rules deliberately don't let customers delete them, and a shop
/// has to keep order records anyway. Staff accounts are removed by an admin.
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  String _friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Your password is incorrect.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'requires-recent-login':
          return 'For security, please log out, log in again, and retry.';
      }
    }
    debugPrint('Delete account failed: $e');
    final code = e is FirebaseAuthException ? ' (${e.code})' : '';
    return 'Could not delete the account$code. Please try again.';
  }

  Future<void> _deleteAll(CollectionReference<Map<String, dynamic>> col) async {
    final snap = await col.get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  Future<void> _delete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null || !FirebaseStatus.isInitialized) {
        throw FirebaseAuthException(code: 'no-current-user');
      }
      // 1. Prove it is the owner. If this fails, nothing has been touched.
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: _password.text));

      final db = FirebaseFirestore.instance;
      final uid = user.uid;

      // 2. Remove what the rules let this person remove.
      await _deleteAll(db.collection('users').doc(uid).collection('cart'));
      await _deleteAll(db.collection('users').doc(uid).collection('wishlist'));
      final addresses = await db.collection('addresses').where('userId', isEqualTo: uid).get();
      if (addresses.docs.isNotEmpty) {
        final batch = db.batch();
        for (final d in addresses.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }

      // 3. Blank the profile (the document itself can't be deleted by rule).
      await db.collection('users').doc(uid).update({
        'fullName': 'Deleted User',
        'email': '',
        'phone': '',
        'avatarUrl': null,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'notificationPrefs': FieldValue.delete(),
      });

      // 4. Finally delete the login itself.
      await user.delete();
      await authRepository.logout();

      if (!mounted) return;
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      router.go(loggedOutRoute());
      messenger.showSnackBar(const SnackBar(content: Text('Your account has been deleted.')));
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(userProfileProvider).role != 'customer';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Delete Account', style: AppTextStyles.h4)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: _busy ? null : () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              if (isStaff) ...[
                Text(
                  'Staff accounts can\u2019t be deleted from the app. Ask the store admin to remove this account.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ] else ...[
                Text(
                  'This permanently deletes your profile, cart, wishlist and saved addresses, and you will be logged out. '
                  'This cannot be undone.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Your past orders, reviews and support tickets are kept for the store\u2019s records, without your profile details.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: AppDimens.md),
                Form(
                  key: _formKey,
                  child: AppTextField(
                    label: 'Confirm with your password',
                    hint: 'Your current password',
                    controller: _password,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppDimens.lg),
                ElevatedButton(
                  onPressed: _busy ? null : _delete,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: _busy
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text('Delete My Account', style: AppTextStyles.buttonLarge),
                ),
                const SizedBox(height: AppDimens.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
