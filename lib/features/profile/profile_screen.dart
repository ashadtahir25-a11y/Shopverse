import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/data/auth_repository.dart';
import '../../core/widgets/user_avatar.dart';
import '../cart/providers/cart_provider.dart';
import '../orders/providers/orders_provider.dart';
import '../wishlist/providers/wishlist_provider.dart';
import '../checkout/providers/address_provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/surface_card.dart';
import 'providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _menuItems = [
    (Icons.receipt_long_outlined, 'My Orders', '/orders'),
    (Icons.favorite_border_rounded, 'Wishlist', null),
    (Icons.location_on_outlined, 'Addresses', '/checkout/address'),
    (Icons.payment_outlined, 'Payment Methods', null),
    (Icons.notifications_none_rounded, 'Notifications', '/notifications'),
    (Icons.star_border_rounded, 'Reviews', null),
    (Icons.assignment_return_outlined, 'Returns', null),
    (Icons.settings_outlined, 'Settings', '/settings'),
    (Icons.help_outline_rounded, 'Help & Support', '/help-support'),
  ];

  static const _adminMenuItem = (
    Icons.admin_panel_settings_outlined,
    'Admin Dashboard',
    '/admin',
  );
  static const _logoutMenuItem = (Icons.logout_rounded, 'Logout', 'LOGOUT');

  List<(IconData, String, String?)> _visibleMenuItems(bool isAdmin) => [
    ..._menuItems,
    if (isAdmin) _adminMenuItem,
    _logoutMenuItem,
  ];

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await authRepository.logout();

    // Clear session-scoped local state so the next account doesn't see
    // the previous user's cart/orders/etc.
    ref.read(cartProvider.notifier).clear();
    ref.read(addressProvider.notifier).clear();

    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final ordersCount = ref.watch(ordersProvider).length;
    final wishlistCount = ref.watch(wishlistProvider).length;
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -40,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.md,
                        AppDimens.xl,
                        AppDimens.md,
                        AppDimens.xl,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                UserAvatar(
                                  avatarUrl: profile.avatarUrl,
                                  name: profile.name,
                                  size: 72,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: AppTextStyles.h4.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.email,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      context.push('/profile/edit'),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatPill(
                                    value: '$ordersCount',
                                    label: 'Orders',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatPill(
                                    value: '$wishlistCount',
                                    label: 'Wishlist',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatPill(
                                    value: '$cartCount',
                                    label: 'In Cart',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppDimens.md),
            sliver: SliverToBoxAdapter(
              child: SurfaceCard(
                child: Column(
                  children: List.generate(
                    _visibleMenuItems(profile.isAdminUser).length,
                    (i) {
                      final items = _visibleMenuItems(profile.isAdminUser);
                      final item = items[i];
                      final isLast = i == items.length - 1;
                      final route = item.$3;
                      return Column(
                        children: [
                          ListTile(
                                leading: Icon(
                                  item.$1,
                                  color: isLast
                                      ? AppColors.error
                                      : AppColors.textPrimary,
                                  size: 22,
                                ),
                                title: Text(
                                  item.$2,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isLast
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () {
                                  if (route == 'LOGOUT') {
                                    _handleLogout(context, ref);
                                  } else if (route != null) {
                                    context.push(route);
                                  }
                                },
                              )
                              .animate()
                              .fadeIn(delay: (i * 30).ms, duration: 250.ms)
                              .slideX(begin: 0.03, end: 0),
                          if (!isLast) const Divider(height: 1, indent: 56),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      borderRadius: AppDimens.radiusMd,
      opacity: 0.16,
      blurSigma: 14,
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h4.copyWith(color: Colors.white)),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
