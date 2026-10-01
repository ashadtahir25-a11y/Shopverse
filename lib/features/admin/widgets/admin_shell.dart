import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/routes/app_router.dart';

class _AdminNavItem {
  final IconData icon;
  final String label;
  final String? route; // null = not built yet in this increment

  const _AdminNavItem(this.icon, this.label, this.route);
}

const _navItems = [
  _AdminNavItem(Icons.dashboard_outlined, 'Dashboard', AppRoutes.admin),
  _AdminNavItem(
    Icons.inventory_2_outlined,
    'Products',
    AppRoutes.adminProducts,
  ),
  _AdminNavItem(
    Icons.category_outlined,
    'Categories',
    AppRoutes.adminCategories,
  ),
  _AdminNavItem(Icons.receipt_long_outlined, 'Orders', AppRoutes.adminOrders),
  _AdminNavItem(
    Icons.people_outline_rounded,
    'Customers',
    AppRoutes.adminCustomers,
  ),
  _AdminNavItem(Icons.local_offer_outlined, 'Coupons', AppRoutes.adminCoupons),
  _AdminNavItem(Icons.star_border_rounded, 'Reviews', AppRoutes.adminReviews),
  _AdminNavItem(
    Icons.assignment_return_outlined,
    'Returns',
    AppRoutes.adminReturns,
  ),
  _AdminNavItem(
    Icons.support_agent_outlined,
    'Support',
    AppRoutes.adminSupport,
  ),

  _AdminNavItem(Icons.campaign_outlined, 'Banners', AppRoutes.adminBanners),
];

/// Breakpoint below which the fixed sidebar collapses into a drawer
/// (opened via a hamburger button in an AppBar) — keeps the dashboard
/// usable on phones/narrow browser windows, not just desktop-width web.
const _mobileBreakpoint = 800.0;

/// Shared layout for every admin screen. Only "Dashboard" and "Products"
/// are wired to real routes so far — the rest show a "coming soon" notice
/// so the full navigation structure is visible from day one.
class AdminShell extends StatelessWidget {
  final String activeLabel;
  final Widget child;

  const AdminShell({super.key, required this.activeLabel, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          // The app's global AppBarTheme sets a dark iconTheme (for the
          // normal light-background screens) which otherwise overrides
          // `foregroundColor` here and made the hamburger/menu icon
          // render dark-on-dark (invisible) on this navy admin AppBar.
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            activeLabel,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1A1A2E),
          child: _SidebarContent(activeLabel: activeLabel),
        ),
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: ColoredBox(
              color: const Color(0xFF1A1A2E),
              child: _SidebarContent(activeLabel: activeLabel),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String activeLabel;
  const _SidebarContent({required this.activeLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'ShopVerse Admin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: AppDimens.sm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _navItems.map((item) {
                final isActive = item.label == activeLabel;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(
                          context,
                        ).maybePop(); // close drawer if open
                        if (item.route != null) {
                          context.go(item.route!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${item.label} management is coming in the next update',
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white54,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (item.route == null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Soon',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SidebarActionTile(
                  icon: Icons.storefront_outlined,
                  label: 'Back to Store',
                  onTap: () => context.go(AppRoutes.home),
                ),
                _SidebarActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: () async {
                    await authRepository.logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white54),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
