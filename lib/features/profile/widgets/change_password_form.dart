import 'package:flutter/material.dart';
import '../../../core/data/password_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Old password -> new password -> confirm. Shared by the customer's
/// "Change Password" sheet and (after the personal-key step) the admin's
/// security dialog.
class ChangePasswordForm extends StatefulWidget {
  final VoidCallback onChanged;
  const ChangePasswordForm({super.key, required this.onChanged});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await changeCurrentUserPassword(oldPassword: _old.text, newPassword: _new.text);
      if (mounted) widget.onChanged();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyPasswordError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Old Password',
            hint: 'Enter your current password',
            controller: _old,
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
          ),
          const SizedBox(height: AppDimens.md),
          AppTextField(
            label: 'New Password',
            hint: 'At least 8 characters',
            controller: _new,
            isPassword: true,
            prefixIcon: Icons.lock_reset_rounded,
            validator: (v) {
              if (v == null || v.length < 8) return 'Minimum 8 characters';
              if (v == _old.text) return 'New password must be different';
              return null;
            },
          ),
          const SizedBox(height: AppDimens.md),
          AppTextField(
            label: 'Confirm New Password',
            hint: 'Re-enter the new password',
            controller: _confirm,
            isPassword: true,
            prefixIcon: Icons.lock_reset_rounded,
            validator: (v) => v != _new.text ? 'Passwords do not match' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDimens.sm),
            Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppDimens.lg),
          PrimaryButton(label: 'Change Password', isLoading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
