// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/product_card.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../reviews/providers/reviews_provider.dart';
import '../../reviews/models/review_model.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../widgets/variant_selector.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late Product product;
  final Map<String, String> _selectedOptions = {};
  int _imageIndex = 0;
  int _quantity = 1;
  bool _defaultsInitialized = false;

  void _ensureDefaultsInitialized(Product loadedProduct) {
    if (_defaultsInitialized) return;
    for (final v in loadedProduct.variants) {
      _selectedOptions[v.name] = v.options.first.id;
    }
    _defaultsInitialized = true;
  }

  List<Product> _relatedProducts(List<Product> allProducts) => allProducts
      .where((p) => p.category == product.category && p.id != product.id)
      .take(6)
      .toList();

  Map<String, String> get _selectedVariantLabels {
    final labels = <String, String>{};
    for (final attr in product.variants) {
      final optId = _selectedOptions[attr.name];
      final opt = attr.options.firstWhere(
        (o) => o.id == optId,
        orElse: () => attr.options.first,
      );
      labels[attr.name] = opt.label;
    }
    return labels;
  }

  void _addToCart() {
    ref
        .read(cartProvider.notifier)
        .add(product, _selectedVariantLabels, quantity: _quantity);

    // Grab these NOW, while this page's context is definitely alive.
    // The "View Cart" action used to call `context.push` later, from
    // inside the SnackBar — if the user had already left this page by
    // then, that context was dead (a likely trigger of the red
    // "_dependents.isEmpty" assertion screen).
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to cart'),
          duration: const Duration(seconds: 2),
          // Floating + bottom margin keeps it ABOVE this page's sticky
          // "Add to Cart / Buy Now" bar instead of covering it.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => router.push('/cart'),
          ),
        ),
      );
  }

  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // The messenger is app-wide, so without this the "Added to cart —
    // View Cart" toast kept showing on completely unrelated screens
    // (e.g. Edit Profile) after leaving this page. Deferred to after
    // the frame because the widget tree is locked while disposing.
    final messenger = _messenger;
    WidgetsBinding.instance.addPostFrameCallback((_) => messenger?.clearSnackBars());
    super.dispose();
  }

  /// Used by "Buy Now" — adds to cart without a confirmation SnackBar,
  /// since we're navigating straight to checkout anyway. Showing the
  /// "Added to cart" toast here used to visually "follow" across the
  /// next couple of screens (Checkout, Order Confirmation) because
  /// SnackBars in this app share one root-level ScaffoldMessenger and
  /// outlive the page that triggered them until their duration expires.
  void _addToCartQuietly() {
    ref
        .read(cartProvider.notifier)
        .add(product, _selectedVariantLabels, quantity: _quantity);
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return productAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Something went wrong. Please try again.')),
      ),
      data: (fetched) {
        if (fetched == null) {
          return const Scaffold(body: Center(child: Text('Product not found')));
        }
        product = fetched;
        _ensureDefaultsInitialized(fetched);
        final allProducts = ref
            .watch(productsProvider)
            .maybeWhen(data: (list) => list, orElse: () => <Product>[]);
        final isWishlisted = ref
            .watch(wishlistProvider)
            .any((p) => p.id == product.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGallery(context),
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.brand.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(product.name, style: AppTextStyles.h3),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: product.rating,
                                    itemCount: 5,
                                    itemSize: 16,
                                    unratedColor: AppColors.border,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star_rounded,
                                      color: AppColors.star,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${product.rating} (${product.reviewCount} reviews)',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PriceText(product.price,
                                    style: AppTextStyles.h3.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (product.hasDiscount) ...[
                                    const SizedBox(width: 10),
                                    PriceText(product.originalPrice!,
                                      style: AppTextStyles.priceStrike,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '-${product.discountPercent}%',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    product.inStock
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 16,
                                    color: product.inStock
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    product.inStock
                                        ? 'In Stock (${product.stock} available)'
                                        : 'Out of Stock',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: product.inStock
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppDimens.lg),
                              ...product.variants.map(
                                (attr) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppDimens.lg,
                                  ),
                                  child: VariantSelector(
                                    attribute: attr,
                                    selectedOptionId:
                                        _selectedOptions[attr.name],
                                    onSelected: (id) => setState(
                                      () => _selectedOptions[attr.name] = id,
                                    ),
                                  ),
                                ),
                              ),

                              Text(
                                'Quantity',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove_rounded,
                                    onTap: () => setState(
                                      () => _quantity = _quantity > 1
                                          ? _quantity - 1
                                          : 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: AppTextStyles.h4,
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add_rounded,
                                    onTap: () => setState(
                                      () =>
                                          _quantity = _quantity < product.stock
                                          ? _quantity + 1
                                          : _quantity,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppDimens.lg),
                              _buildDeliveryCard(),
                              const SizedBox(height: AppDimens.lg),

                              Text('Description', style: AppTextStyles.h4),
                              const SizedBox(height: 8),
                              Text(
                                product.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: AppDimens.lg),
                              _buildSpecRow('SKU', product.sku),
                              _buildSpecRow('Brand', product.brand),
                              _buildSpecRow('Category', product.category),

                              const SizedBox(height: AppDimens.xl),
                              _buildReviewsSection(),

                              if (_relatedProducts(allProducts).isNotEmpty) ...[
                                const SizedBox(height: AppDimens.xl),
                                Text(
                                  'You Might Also Like',
                                  style: AppTextStyles.h4,
                                ),
                                const SizedBox(height: AppDimens.md),
                                SizedBox(
                                  height: 295,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _relatedProducts(
                                      allProducts,
                                    ).length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 14),
                                    itemBuilder: (context, i) {
                                      final rp = _relatedProducts(
                                        allProducts,
                                      )[i];
                                      return SizedBox(
                                        width: 160,
                                        child: ProductCard(
                                          product: rp,
                                          isWishlisted: ref
                                              .watch(wishlistProvider)
                                              .any((p) => p.id == rp.id),
                                          onWishlistTap: () => ref
                                              .read(wishlistProvider.notifier)
                                              .toggle(rp),
                                          onTap: () => context.pushReplacement(
                                            '/product/${rp.id}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppDimens.xl),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomActionBar(isWishlisted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGallery(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: product.images.isEmpty ? 1 : product.images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (context, i) => ProductImagePlaceholder(
              category: product.category,
              seed: product.id,
              imageUrl: i < product.images.length ? product.images[i] : null,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              product.images.isEmpty ? 1 : product.images.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _imageIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _imageIndex ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Delivery',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Estimated: 3–5 business days',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = ref
        .watch(reviewsProvider)
        .maybeWhen(
          data: (all) => all.where((r) => r.productId == product.id).toList(),
          orElse: () => <Review>[],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews (${reviews.length})', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => context.push('/reviews/write/${product.id}'),
              child: const Text('Write a Review'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          Text(
            'No reviews yet — be the first to review this product.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          ...reviews.map(
            (review) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          review.userName[0],
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        review.userName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (review.verifiedPurchase) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Verified',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  RatingBarIndicator(
                    rating: review.rating.toDouble(),
                    itemCount: 5,
                    itemSize: 14,
                    unratedColor: AppColors.border,
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star_rounded, color: AppColors.star),
                  ),
                  if (review.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      review.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActionBar(bool isWishlisted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.sm,
        AppDimens.md,
        AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Icon(
                  isWishlisted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isWishlisted ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Add to Cart',
                outlined: true,
                icon: Icons.shopping_cart_outlined,
                onPressed: product.inStock ? _addToCart : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Buy Now',
                onPressed: product.inStock
                    ? () {
                        _addToCartQuietly();
                        context.push('/checkout/address');
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
