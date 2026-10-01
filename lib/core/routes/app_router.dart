import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../shell/main_nav_shell.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/product/screens/search_screen.dart';
import '../../features/product/screens/product_listing_screen.dart';
import '../../features/product/screens/product_details_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/screens/address_screen.dart';
import '../../features/checkout/screens/add_address_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_confirmation_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_details_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/returns/screens/return_request_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/support/screens/help_support_screen.dart';
import '../../features/support/screens/contact_support_screen.dart';
import '../../features/support/screens/my_tickets_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_products_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_customers_screen.dart';
import '../../features/admin/screens/admin_coupons_screen.dart';
import '../../features/admin/screens/admin_banners_screen.dart';
import '../../features/admin/screens/admin_reviews_screen.dart';
import '../../features/admin/screens/admin_returns_screen.dart';
import '../../features/admin/screens/admin_support_screen.dart';

/// Route name/path constants — avoids magic strings across the app.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const categories = '/categories';
  static const search = '/search';
  static const productListing = '/products';
  static const productDetails = '/product'; // + /{id}
  static const cart = '/cart';
  static const checkoutAddress = '/checkout/address';
  static const checkoutAddAddress = '/checkout/address/add';
  static const checkoutSummary = '/checkout/summary';
  static const orderConfirmation = '/order-confirmation';
  static const orders = '/orders'; // + /{id}, /{id}/track
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const helpSupport = '/help-support';
  static const contactSupport = '/help-support/contact';
  static const myTickets = '/help-support/tickets';
  static const editProfile = '/profile/edit';
  static const admin = '/admin';
  static const adminProducts = '/admin/products';
  static const adminOrders = '/admin/orders';
  static const adminCategories = '/admin/categories';
  static const adminCustomers = '/admin/customers';
  static const adminCoupons = '/admin/coupons';
  static const adminBanners = '/admin/banners';
  static const adminReviews = '/admin/reviews';
  static const adminReturns = '/admin/returns';
  static const adminSupport = '/admin/support';
}

/// A soft fade + upward-slide transition used across the app for a
/// smoother, more premium feel than the platform-default push transition.
CustomTransitionPage<void> _fadeSlidePage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const RegisterScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const ForgotPasswordScreen(), state: state),
    ),

    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainNavShell(),
    ),

    GoRoute(
      path: AppRoutes.categories,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const CategoriesScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.search,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const SearchScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.productListing,
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['category'];
        final title = state.uri.queryParameters['title'] ?? 'Products';
        return _fadeSlidePage(
          child: ProductListingScreen(categoryId: categoryId, title: title),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.productDetails}/:id',
      pageBuilder: (context, state) => _fadeSlidePage(
        child: ProductDetailsScreen(productId: state.pathParameters['id']!),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.cart,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const CartScreen(), state: state),
    ),

    // Checkout flow
    GoRoute(
      path: AppRoutes.checkoutAddress,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const AddressScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.checkoutAddAddress,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const AddAddressScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.checkoutSummary,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const CheckoutScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.orderConfirmation,
      pageBuilder: (context, state) => _fadeSlidePage(
        child: OrderConfirmationScreen(orderId: state.extra as String? ?? ''),
        state: state,
      ),
    ),
    // Orders
    GoRoute(
      path: AppRoutes.orders,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const OrdersScreen(), state: state),
    ),
    GoRoute(
      path: '${AppRoutes.orders}/:id',
      pageBuilder: (context, state) => _fadeSlidePage(
        child: OrderDetailsScreen(orderId: state.pathParameters['id']!),
        state: state,
      ),
    ),
    GoRoute(
      path: '${AppRoutes.orders}/:id/track',
      pageBuilder: (context, state) => _fadeSlidePage(
        child: OrderTrackingScreen(orderId: state.pathParameters['id']!),
        state: state,
      ),
    ),

    // Returns
    GoRoute(
      path: '/returns/new/:orderId/:productId',
      pageBuilder: (context, state) => _fadeSlidePage(
        child: ReturnRequestScreen(
          orderId: state.pathParameters['orderId']!,
          productId: state.pathParameters['productId']!,
        ),
        state: state,
      ),
    ),

    // Reviews
    GoRoute(
      path: '/reviews/write/:productId',
      pageBuilder: (context, state) => _fadeSlidePage(
        child: WriteReviewScreen(
          productId: state.pathParameters['productId']!,
          orderId: state.uri.queryParameters['orderId'],
        ),
        state: state,
      ),
    ),

    // Phase 5: Settings, Notifications, Help & Support, Edit Profile
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const SettingsScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const NotificationsScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.helpSupport,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const HelpSupportScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.contactSupport,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const ContactSupportScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.myTickets,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const MyTicketsScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      pageBuilder: (context, state) =>
          _fadeSlidePage(child: const EditProfileScreen(), state: state),
    ),

    // Phase 7: Admin Dashboard
    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminProducts,
      builder: (context, state) => const AdminProductsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminOrders,
      builder: (context, state) => const AdminOrdersScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminCategories,
      builder: (context, state) => const AdminCategoriesScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminCustomers,
      builder: (context, state) => const AdminCustomersScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminCoupons,
      builder: (context, state) => const AdminCouponsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminBanners,
      builder: (context, state) => const AdminBannersScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminReviews,
      builder: (context, state) => const AdminReviewsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminReturns,
      builder: (context, state) => const AdminReturnsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminSupport,
      builder: (context, state) => const AdminSupportScreen(),
    ),
  ],
);
