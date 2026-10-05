// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../providers/admin_permissions.dart'
    show roleCanAccess, firstAccessibleSection;
import '../providers/admin_section_routes.dart';

/// Gates an admin screen behind two checks:
/// 1. Is this user staff at all (any role other than "customer")?
/// 2. Does their specific role have access to [section]?
///
/// Previously this only checked #1 — meaning support_staff, order_manager,
/// product_manager, manager and admin were all functionally identical:
/// any one of them could open every admin screen. Each admin screen now
/// passes its own `activeLabel` as [section] so this can actually enforce
/// the per-role breakdown (see admin_permissions.dart).
class AdminGuard extends ConsumerWidget {
  final String section;
  final Widget child;

  const AdminGuard({super.key, required this.section, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (!profile.isAdminUser) {
      return _NotAuthorized(
        title: 'Admin access required',
        message: 'This area is for staff accounts only.',
        primaryLabel: 'Back to Store',
        onPrimary: () => context.go(AppRoutes.home),
      );
    }

    if (!roleCanAccess(profile.role, section)) {
      final fallback = firstAccessibleSection(profile.role);
      final fallbackRoute = fallback != null
          ? kAdminSectionRoutes[fallback]
          : null;

      return _NotAuthorized(
        title: 'You don\u2019t have access to $section',
        message:
            'Your role (${profile.role}) doesn\u2019t include this section. Contact an admin if you think this is wrong.',
        primaryLabel: fallbackRoute != null
            ? 'Go to $fallback'
            : 'Back to Store',
        onPrimary: () => fallbackRoute != null
            ? context.go(fallbackRoute)
            : context.go(AppRoutes.home),
      );
    }

    return child;
  }
}

class _NotAuthorized extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  const _NotAuthorized({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  title,
                  style: AppTextStyles.h4,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                SizedBox(
                  width: 220,
                  child: PrimaryButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
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
