import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../../features/product/models/product_model.dart';

/// Product image tile. Shows the product's real uploaded photo
/// (`imageUrl` — a Cloudinary URL from the admin's product form) when one
/// exists; otherwise falls back to a local gradient + category icon,
/// which is instant and never fails (no network dependency for products
/// that don't have a photo yet).
class ProductImagePlaceholder extends StatelessWidget {
  final String category;
  final String? seed;
  final String? imageUrl;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductImagePlaceholder({
    super.key,
    required this.category,
    this.seed,
    this.imageUrl,
    this.height,
    this.borderRadius,
  });

  static const Map<String, IconData> _icons = {
    'electronics': Icons.devices_rounded,
    'fashion': Icons.checkroom_rounded,
    'shoes': Icons.sports_baseball_rounded,
    'beauty': Icons.spa_rounded,
    'home': Icons.chair_rounded,
    'accessories': Icons.watch_rounded,
  };

  static const List<List<Color>> _gradients = [
    [Color(0xFFEDEBFF), Color(0xFFDCD8FF)],
    [Color(0xFFFFE8E2), Color(0xFFFFD5C9)],
    [Color(0xFFE1F7F0), Color(0xFFC9F0E4)],
    [Color(0xFFE3F1FF), Color(0xFFCFE7FF)],
  ];

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppDimens.radiusLg);
    final hasRealImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: hasRealImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _fallbackTile();
                },
                errorBuilder: (context, error, stackTrace) => _fallbackTile(),
              )
            : _fallbackTile(),
      ),
    );
  }

  Widget _fallbackTile() {
    final varietyKey = seed ?? category;
    final gradient = _gradients[varietyKey.hashCode.abs() % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _icons[category] ?? Icons.shopping_bag_rounded,
          size: 40,
          color: AppColors.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;
  final bool isWishlisted;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ProductImagePlaceholder(
                    category: product.category,
                    seed: product.id,
                    imageUrl: product.images.isNotEmpty
                        ? product.images.first
                        : null,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimens.radiusLg),
                    ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onWishlistTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: isWishlisted
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Expanded so this text section receives a bounded height
            // (whatever remains after the square image) instead of an
            // unbounded "however much it wants" — that's what makes the
            // SingleChildScrollView below actually able to prevent
            // overflow: it needs a real height budget from its parent to
            // clip/scroll within. Without Expanded, the overflow just
            // moves to this outer Column instead of being fixed. With
            // it, if the text content is ever taller than its allotted
            // space, it clips invisibly inside instead of overflowing
            // the card, regardless of font metrics or content length.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: product.rating,
                            itemCount: 5,
                            itemSize: 12,
                            unratedColor: AppColors.border,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.star,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '(${product.reviewCount})',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs. ${product.price.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.price,
                      ),
                      if (product.hasDiscount)
                        Text(
                          'Rs. ${product.originalPrice!.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.priceStrike,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
