import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/config/app_flow.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/routes/app_router.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../providers/admin_permissions.dart';
import '../providers/admin_section_routes.dart';

const Map<String, IconData> _sectionIcons = {
  'Dashboard': Icons.dashboard_outlined,
  'Products': Icons.inventory_2_outlined,
  'Categories': Icons.category_outlined,
  'Orders': Icons.receipt_long_outlined,
  'Customers': Icons.people_outline_rounded,
  'Coupons': Icons.local_offer_outlined,
  'Banners': Icons.campaign_outlined,
  'Reviews': Icons.star_border_rounded,
  'Returns': Icons.assignment_return_outlined,
  'Support': Icons.support_agent_outlined,
};

/// Breakpoint below which the fixed sidebar collapses into a drawer +
/// bottom nav (opened via a hamburger button in an AppBar) — keeps the
/// dashboard usable on phones/narrow browser windows, not just
/// desktop-width web.
const _mobileBreakpoint = 800.0;

/// How many sections get a direct bottom-nav tab on mobile before the
/// rest fold into "More". 3 keeps the bar from feeling cramped even for
/// admin/manager, who can see every section.
const _primaryTabCount = 3;

/// Shared layout for every admin screen. The sections shown here — in
/// both the sidebar/drawer and the mobile bottom nav — are filtered to
/// whatever the signed-in user's role is actually permitted to open
/// (see admin_permissions.dart); AdminGuard is what stops them from
/// reaching a section directly by route even if it isn't listed here.
class AdminShell extends ConsumerWidget {
  final String activeLabel;
  final Widget child;

  const AdminShell({super.key, required this.activeLabel, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final sections = accessibleSections(profile.role);
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    if (isMobile) {
      final primary = sections.take(_primaryTabCount).toList();
      final overflow = sections.skip(_primaryTabCount).toList();
      final hasOverflow = overflow.isNotEmpty;

      // -1 means the active section isn't one of the primary tabs (it
      // lives behind "More"), in which case the "More" tab is the one
      // that gets highlighted below.
      final activeIndex = primary.indexOf(activeLabel);

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
          child: _SidebarContent(
            activeLabel: activeLabel,
            sections: sections,
            profileName: profile.name,
          ),
        ),
        body: child,
        // Wrapped in a Builder so `Scaffold.of(context)` below resolves
        // against a context that's actually INSIDE this Scaffold's
        // subtree — the outer `context` (AdminShell's own build
        // parameter) is the context this Scaffold is being created IN,
        // not a descendant of it, so Scaffold.of() on that outer
        // context can never find this Scaffold and throws
        // "Scaffold.of() called with a context that does not contain a
        // Scaffold."
        bottomNavigationBar: primary.isEmpty
            ? null
            : Builder(
                builder: (scaffoldContext) => BottomNavigationBar(
                  // A section that lives behind "More" (e.g. Customers)
                  // highlights the "More" tab — it used to fall back to
                  // index 0 and wrongly light up "Dashboard".
                  currentIndex: activeIndex >= 0
                      ? activeIndex
                      : (hasOverflow ? primary.length : 0),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: const Color(0xFF1A1A2E),
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white54,
                  onTap: (i) {
                    if (i < primary.length) {
                      final route = kAdminSectionRoutes[primary[i]];
                      if (route != null) context.go(route);
                    } else {
                      // The "More" tab — open the drawer rather than
                      // duplicating the overflow list in a second widget.
                      Scaffold.of(scaffoldContext).openDrawer();
                    }
                  },
                  items: [
                    ...primary.map(
                      (s) => BottomNavigationBarItem(
                        icon: Icon(_sectionIcons[s]),
                        label: s,
                      ),
                    ),
                    if (hasOverflow)
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.more_horiz_rounded),
                        label: 'More',
                      ),
                  ],
                ),
              ),
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
              child: _SidebarContent(
                activeLabel: activeLabel,
                sections: sections,
                profileName: profile.name,
              ),
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
  final List<String> sections;
  final String profileName;

  const _SidebarContent({
    required this.activeLabel,
    required this.sections,
    required this.profileName,
  });

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ShopVerse Admin',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        profileName,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
              children: sections.map((section) {
                final isActive = section == activeLabel;
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
                        final route = kAdminSectionRoutes[section];
                        if (route != null) context.go(route);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _sectionIcons[section] ?? Icons.circle_outlined,
                              size: 20,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                section,
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
                  label: 'View Store',
                  onTap: () => context.go(AppRoutes.home),
                ),
                _SidebarActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: () async {
                    await authRepository.logout();
                    if (context.mounted) context.go(loggedOutRoute());
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
