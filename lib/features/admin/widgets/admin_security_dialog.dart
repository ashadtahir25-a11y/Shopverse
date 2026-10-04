import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/widgets/change_password_form.dart';
import '../providers/admin_key_service.dart';

/// Opens the admin's secure password-change flow:
///   first time  -> set a personal key (permanent) -> change password
///   afterwards  -> enter personal key -> change password
void showAdminSecurityDialog(BuildContext context) {
  showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const _AdminSecurityDialog());
}

enum _Step { loading, setKey, enterKey, changePassword, error }

class _AdminSecurityDialog extends StatefulWidget {
  const _AdminSecurityDialog();

  @override
  State<_AdminSecurityDialog> createState() => _AdminSecurityDialogState();
}

class _AdminSecurityDialogState extends State<_AdminSecurityDialog> {
  static const _maxAttempts = 5;

  _Step _step = _Step.loading;
  final _key = TextEditingController();
  final _keyConfirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _key.dispose();
    _keyConfirm.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final has = await adminKeyService.hasKey();
      if (mounted) setState(() => _step = has ? _Step.enterKey : _Step.setKey);
    } catch (_) {
      if (mounted) {
        setState(() {
          _step = _Step.error;
          _message = 'Could not reach the security settings. Make sure the Firestore rules for "adminKeys" are deployed.';
        });
      }
    }
  }

  Future<void> _saveKey() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await adminKeyService.setKey(_key.text);
      if (mounted) setState(() { _step = _Step.changePassword; _message = null; });
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not save the key. It may already be set.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkKey() async {
    if (_key.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final ok = await adminKeyService.verify(_key.text);
      if (!mounted) return;
      if (ok) {
        setState(() { _step = _Step.changePassword; _message = null; });
      } else {
        _attempts++;
        if (_attempts >= _maxAttempts) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Too many wrong attempts. Try again later.')));
          return;
        }
        setState(() => _message = 'Incorrect personal key (${_maxAttempts - _attempts} attempts left).');
        _key.clear();
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not verify the key. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _title => switch (_step) {
        _Step.setKey => 'Set Your Personal Key',
        _Step.enterKey => 'Enter Personal Key',
        _Step.changePassword => 'Change Password',
        _ => 'Security',
      };

  Widget _body() {
    switch (_step) {
      case _Step.loading:
        return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
      case _Step.error:
        return Text(_message ?? 'Something went wrong.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error));
      case _Step.setKey:
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This key protects password changes on the admin account. '
                'Once saved it can NEVER be changed or recovered from the app — remember it carefully.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppDimens.md),
              AppTextField(
                label: 'Personal Key',
                hint: 'At least 6 characters',
                controller: _key,
                isPassword: true,
                prefixIcon: Icons.key_rounded,
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: AppDimens.md),
              AppTextField(
                label: 'Confirm Key',
                hint: 'Re-enter the key',
                controller: _keyConfirm,
                isPassword: true,
                prefixIcon: Icons.key_rounded,
                validator: (v) => v != _key.text ? 'Keys do not match' : null,
              ),
              if (_message != null) ...[
                const SizedBox(height: AppDimens.sm),
                Text(_message!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppDimens.lg),
              PrimaryButton(label: 'Save Key & Continue', isLoading: _busy, onPressed: _saveKey),
            ],
          ),
        );
      case _Step.enterKey:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the personal key you set to continue.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimens.md),
            AppTextField(
              label: 'Personal Key',
              hint: 'Your personal key',
              controller: _key,
              isPassword: true,
              prefixIcon: Icons.key_rounded,
            ),
            if (_message != null) ...[
              const SizedBox(height: AppDimens.sm),
              Text(_message!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppDimens.lg),
            PrimaryButton(label: 'Continue', isLoading: _busy, onPressed: _checkKey),
          ],
        );
      case _Step.changePassword:
        return ChangePasswordForm(
          onChanged: () {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            messenger.showSnackBar(const SnackBar(content: Text('Password changed successfully')));
          },
        );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_title, style: AppTextStyles.h4)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              _body(),
            ],
          ),
        ),
      ),
    );
  }
}
