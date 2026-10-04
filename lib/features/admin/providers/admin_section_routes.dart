import '../../../core/routes/app_router.dart';

/// Maps each canonical section name (see admin_permissions.dart) to its
/// route — used by AdminGuard to redirect a staff member to a section
/// their role can actually open.
const Map<String, String> kAdminSectionRoutes = {
  'Dashboard': AppRoutes.admin,
  'Products': AppRoutes.adminProducts,
  'Categories': AppRoutes.adminCategories,
  'Orders': AppRoutes.adminOrders,
  'Customers': AppRoutes.adminCustomers,
  'Coupons': AppRoutes.adminCoupons,
  'Banners': AppRoutes.adminBanners,
  'Reviews': AppRoutes.adminReviews,
  'Returns': AppRoutes.adminReturns,
  'Support': AppRoutes.adminSupport,
};