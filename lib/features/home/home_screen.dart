import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/widgets/product_card.dart';
import '../cart/providers/cart_provider.dart';
import '../wishlist/providers/wishlist_provider.dart';
import '../notifications/providers/notifications_provider.dart';
import '../categories/category_model.dart';
import '../categories/category_provider.dart';
import '../product/models/product_model.dart';
import '../product/providers/product_provider.dart';
import 'widgets/section_header.dart';
import 'widgets/promo_banner.dart';
import 'widgets/category_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final bestSellersAsync = ref.watch(bestSellerProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.sm,
            ),
            children: [
              const _HomeHeader(),
              const SizedBox(height: AppDimens.md),
              const PromoBannerCarousel()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppDimens.lg),

              SectionHeader(
                title: 'Categories',
                onSeeAll: () => context.push(AppRoutes.categories),
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
              const SizedBox(height: AppDimens.md),
              SizedBox(
                height: 96,
                child: categoriesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Couldn\u2019t load categories',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  data: (categories) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final ProductCategory cat = categories[i];
                      return CategoryItem(
                        category: cat,
                        onTap: () => context.push(
                          '${AppRoutes.productListing}?category=${cat.id}&title=${cat.name}',
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.lg),

              SectionHeader(
                title: 'Featured Products',
                onSeeAll: () => context.push(
                  '${AppRoutes.productListing}?title=Featured Products',
                ),
              ),
              const SizedBox(height: AppDimens.md),
              _AsyncProductGrid(
                productsAsync: featuredAsync,
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: AppDimens.lg),

              SectionHeader(
                title: 'Best Sellers',
                onSeeAll: () => context.push(
                  '${AppRoutes.productListing}?title=Best Sellers',
                ),
              ),
              const SizedBox(height: AppDimens.md),
              _AsyncProductHorizontalList(
                productsAsync: bestSellersAsync,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: AppDimens.lg),

              SectionHeader(
                title: 'New Arrivals',
                onSeeAll: () => context.push(
                  '${AppRoutes.productListing}?title=New Arrivals',
                ),
              ),
              const SizedBox(height: AppDimens.md),
              _AsyncProductHorizontalList(productsAsync: newArrivalsAsync),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deliver to', style: AppTextStyles.caption),
                  Text(
                    'Karachi, Sindh',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _HeaderIconButton(
              icon: Icons.notifications_none_rounded,
              badgeCount: unreadCount,
              onTap: () => context.push(AppRoutes.notifications),
            ),
            const SizedBox(width: 10),
            _HeaderIconButton(
              icon: Icons.shopping_cart_outlined,
              badgeCount: cartCount,
              onTap: () => context.push(AppRoutes.cart),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        GestureDetector(
          onTap: () => context.push(AppRoutes.search),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  'Search products, brands, SKU...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: badges.Badge(
          showBadge: badgeCount > 0,
          badgeContent: Text(
            '$badgeCount',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent),
          position: badges.BadgePosition.topEnd(top: -6, end: -6),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _AsyncProductGrid extends ConsumerWidget {
  final AsyncValue<List<Product>> productsAsync;
  const _AsyncProductGrid({required this.productsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return productsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) =>
          Text('Couldn\u2019t load products', style: AppTextStyles.caption),
      data: (products) {
        if (products.isEmpty) {
          return Text(
            'No products yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          );
        }
        final wishlist = ref.watch(wishlistProvider);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.56,
          ),
          itemBuilder: (context, i) {
            final product = products[i];
            return ProductCard(
              product: product,
              isWishlisted: wishlist.any((p) => p.id == product.id),
              onWishlistTap: () =>
                  ref.read(wishlistProvider.notifier).toggle(product),
              onTap: () =>
                  context.push('${AppRoutes.productDetails}/${product.id}'),
            );
          },
        );
      },
    );
  }
}

class _AsyncProductHorizontalList extends ConsumerWidget {
  final AsyncValue<List<Product>> productsAsync;
  const _AsyncProductHorizontalList({required this.productsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return productsAsync.when(
      loading: () => const SizedBox(
        height: 295,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => SizedBox(
        height: 60,
        child: Text(
          'Couldn\u2019t load products',
          style: AppTextStyles.caption,
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Text(
            'No products yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          );
        }
        final wishlist = ref.watch(wishlistProvider);
        return SizedBox(
          height: 295,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final product = products[i];
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: product,
                  isWishlisted: wishlist.any((p) => p.id == product.id),
                  onWishlistTap: () =>
                      ref.read(wishlistProvider.notifier).toggle(product),
                  onTap: () =>
                      context.push('${AppRoutes.productDetails}/${product.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
