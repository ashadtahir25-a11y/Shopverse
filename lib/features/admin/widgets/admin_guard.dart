import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/routes/app_router.dart';
import '../../profile/providers/user_profile_provider.dart';

/// Wraps every admin screen. Reads the current user's role from the same
/// live-synced `userProfileProvider` the rest of the app uses — if it
/// isn't an admin-level role, shows an "Access Denied" screen instead of
/// the protected content. This is a UI-layer convenience; the real
/// security boundary is the Firestore Rules (`isAdmin()` — see
/// firebase/firestore.rules), which enforce this independently of
/// whatever the client shows.
class AdminGuard extends ConsumerWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (!profile.isAdminUser) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppDimens.md),
                Text('Access Denied', style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Text(
                  'This area is for store staff only.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                PrimaryButton(
                  label: 'Back to Shopping',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
