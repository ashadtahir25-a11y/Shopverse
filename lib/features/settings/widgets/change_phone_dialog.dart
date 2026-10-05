import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/providers/user_profile_provider.dart';

void showChangePhoneDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _ChangePhoneDialog());
}

class _ChangePhoneDialog extends ConsumerStatefulWidget {
  const _ChangePhoneDialog();

  @override
  ConsumerState<_ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends ConsumerState<_ChangePhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: ref.read(userProfileProvider).phone);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final phone = _phone.text.trim();
    try {
      final uid = FirebaseStatus.isInitialized ? FirebaseAuth.instance.currentUser?.uid : null;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'phone': phone});
      }
      ref.read(userProfileProvider.notifier).update(phone: phone);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Phone number updated')));
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not update the phone number. Please try again.');
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
                    Expanded(child: Text('Change Phone', style: AppTextStyles.h4)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Phone Number',
                  hint: '03XX-XXXXXXX',
                  controller: _phone,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppDimens.lg),
                PrimaryButton(label: 'Save', isLoading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
