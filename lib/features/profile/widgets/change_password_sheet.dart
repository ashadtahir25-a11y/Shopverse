import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import 'change_password_form.dart';

/// Bottom sheet with the old/new/confirm form (customers and non-admin
/// staff). Admins go through the personal-key dialog instead.
void showChangePasswordSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppDimens.lg,
        right: AppDimens.lg,
        top: AppDimens.lg,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppDimens.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password', style: AppTextStyles.h4),
            const SizedBox(height: AppDimens.md),
            ChangePasswordForm(
              onChanged: () {
                Navigator.pop(sheetContext);
                messenger.showSnackBar(const SnackBar(content: Text('Password changed successfully')));
              },
            ),
          ],
        ),
      ),
    ),
  );
}
