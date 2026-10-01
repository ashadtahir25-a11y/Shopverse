import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_router.dart';
// import 'banner_model.dart';
import 'banner_provider.dart';

/// Promo banners default to local gradients + icons (instant,
/// network-independent), but admins can also upload a custom photo
/// (Cloudinary) per banner — see the Admin Dashboard's Banners screen
/// (lib/features/admin/screens/admin_banners_screen.dart) and
/// firebase/firestore.rules `banners` collection.
class PromoBannerCarousel extends ConsumerWidget {
  const PromoBannerCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      loading: () => const SizedBox(height: 170),
      error: (e, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        return CarouselSlider(
          options: CarouselOptions(
            height: 170,
            viewportFraction: 0.9,
            autoPlay: true,
            enlargeCenterPage: false,
            autoPlayInterval: const Duration(seconds: 4),
          ),
          items: banners.map((banner) {
            final hasImage =
                banner.imageUrl != null && banner.imageUrl!.isNotEmpty;

            return GestureDetector(
              onTap: banner.targetCategoryId == null
                  ? null
                  : () => context.push(
                      '${AppRoutes.productListing}?category=${banner.targetCategoryId}&title=${banner.title}',
                    ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  gradient: hasImage
                      ? null
                      : LinearGradient(
                          colors: banner.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: banner.gradient.last.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      // A custom admin-uploaded photo (Cloudinary). A dark
                      // scrim sits under the text so it stays readable
                      // over any image — falls back to the gradient tile
                      // if the image fails to load, same reliability
                      // pattern as ProductImagePlaceholder.
                      Image.network(
                        banner.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: banner.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          banner.icon,
                          size: 130,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    if (hasImage)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.md),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        // FittedBox is a deliberate safety net: even if this
                        // content's natural height ever exceeds the banner's
                        // available height (different device text-scale
                        // settings, a longer admin-entered string, etc.), it
                        // scales the whole block down to fit instead of
                        // throwing a RenderFlex overflow.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner.title,
                                style: AppTextStyles.h4.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner.subtitle,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusPill,
                                  ),
                                ),
                                child: Text(
                                  banner.ctaLabel,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: banner.gradient.last,
                                  ),
                                ),
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
          }).toList(),
        );
      },
    );
  }
}
