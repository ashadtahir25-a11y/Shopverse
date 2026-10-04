import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/widgets/product_card.dart';
import 'providers/wishlist_provider.dart';
import 'providers/live_wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live-priced view of the wishlist (see live_wishlist_provider.dart).
    final wishlist = ref.watch(liveWishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Wishlist (${wishlist.length})')),
      body: wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text('Your wishlist is empty', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(
                    'Items you save will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppDimens.md),
              itemCount: wishlist.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.56,
              ),
              itemBuilder: (context, i) {
                final product = wishlist[i];
                return ProductCard(
                  product: product,
                  isWishlisted: true,
                  onWishlistTap: () =>
                      ref.read(wishlistProvider.notifier).toggle(product),
                  onTap: () =>
                      context.push('${AppRoutes.productDetails}/${product.id}'),
                );
              },
            ),
    );
  }
}
