/// Which Admin Dashboard sections each staff role can see and use.
///
/// Section names here match `AdminShell`'s `activeLabel` values exactly —
/// both this map and the sidebar/bottom-nav items key off the same
/// strings, so adding a new section means updating both in one place
/// each (this map, and `_navItems` in admin_shell.dart).
///
/// `customer` deliberately has no entry — AdminGuard treats "no entry"
/// as "no admin access at all", which is what customers should get.
const Map<String, Set<String>> kRolePermissions = {
  'admin': {
    'Dashboard',
    'Products',
    'Categories',
    'Orders',
    'Customers',
    'Coupons',
    'Banners',
    'Reviews',
    'Returns',
    'Support',
  },
  'manager': {
    'Dashboard',
    'Products',
    'Categories',
    'Orders',
    'Customers',
    'Coupons',
    'Banners',
    'Reviews',
    'Returns',
    'Support',
  },
  'product_manager': {
    'Dashboard',
    'Products',
    'Categories',
    'Coupons',
    'Banners',
  },
  'order_manager': {'Dashboard', 'Orders', 'Returns'},
  'support_staff': {'Dashboard', 'Support', 'Reviews', 'Returns'},
};

/// The canonical section order — used both for the sidebar/drawer and to
/// decide which sections go in the mobile bottom nav's primary slots vs.
/// behind "More". Keeping one canonical order avoids the sidebar and
/// bottom nav ever disagreeing about section order.
const List<String> kAdminSectionOrder = [
  'Dashboard',
  'Products',
  'Categories',
  'Orders',
  'Customers',
  'Coupons',
  'Banners',
  'Reviews',
  'Returns',
  'Support',
];

/// True if [role] is allowed to open [section] at all.
bool roleCanAccess(String role, String section) {
  return kRolePermissions[role]?.contains(section) ?? false;
}

/// The sections [role] can see, in canonical order — this is what both
/// the sidebar and the bottom nav iterate over, so a role never sees a
/// section it isn't permitted to use.
List<String> accessibleSections(String role) {
  final allowed = kRolePermissions[role];
  if (allowed == null) return const [];
  return kAdminSectionOrder.where(allowed.contains).toList();
}

/// Where to land a staff member right after login, or where to bounce
/// them back to if they try to open a section their role can't access
/// (e.g. a stale bookmark, or typing the URL directly on web).
/// Prefers "Dashboard" when available since that's the natural landing
/// page; otherwise falls back to the first section the role can see.
String? firstAccessibleSection(String role) {
  final sections = accessibleSections(role);
  if (sections.isEmpty) return null;
  return sections.contains('Dashboard') ? 'Dashboard' : sections.first;
}
