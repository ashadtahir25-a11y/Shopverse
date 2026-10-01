import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

enum SortOption {
  relevance,
  newest,
  priceLowHigh,
  priceHighLow,
  highestRated,
  biggestDiscount,
}

extension on SortOption {
  String get label => switch (this) {
    SortOption.relevance => 'Relevance',
    SortOption.newest => 'Newest',
    SortOption.priceLowHigh => 'Price: Low to High',
    SortOption.priceHighLow => 'Price: High to Low',
    SortOption.highestRated => 'Highest Rated',
    SortOption.biggestDiscount => 'Biggest Discount',
  };
}

class ProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String title;

  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.title = 'Products',
  });

  @override
  ConsumerState<ProductListingScreen> createState() =>
      _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  SortOption _sort = SortOption.relevance;
  RangeValues _priceRange = const RangeValues(0, 80000);
  double _minRating = 0;

  List<Product> _filterAndSort(List<Product> source) {
    var list = widget.categoryId == null
        ? List<Product>.from(source)
        : source.where((p) => p.category == widget.categoryId).toList();

    list = list
        .where(
          (p) => p.price >= _priceRange.start && p.price <= _priceRange.end,
        )
        .toList();
    list = list.where((p) => p.rating >= _minRating).toList();

    switch (_sort) {
      case SortOption.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.highestRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.biggestDiscount:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case SortOption.newest:
        list =
            list.where((p) => p.isNewArrival).toList() +
            list.where((p) => !p.isNewArrival).toList();
        break;
      case SortOption.relevance:
        break;
    }
    return list;
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        priceRange: _priceRange,
        minRating: _minRating,
        onApply: (price, rating) => setState(() {
          _priceRange = price;
          _minRating = rating;
        }),
      ),
    );
  }

  void _openSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            RadioGroup<SortOption>(
              groupValue: _sort,
              onChanged: (v) {
                setState(() => _sort = v!);
                Navigator.pop(context);
              },
              child: Column(
                children: SortOption.values
                    .map(
                      (opt) => RadioListTile<SortOption>(
                        value: opt,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: Text(opt.label, style: AppTextStyles.bodyMedium),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Couldn\u2019t load products',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (source) {
          final results = _filterAndSort(source);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openSort,
                        icon: const Icon(Icons.swap_vert_rounded, size: 18),
                        label: Text(
                          _sort.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          'No products found',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppDimens.md),
                        itemCount: results.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.56,
                            ),
                        itemBuilder: (context, i) {
                          final product = results[i];
                          return ProductCard(
                            product: product,
                            isWishlisted: wishlist.any(
                              (p) => p.id == product.id,
                            ),
                            onWishlistTap: () => ref
                                .read(wishlistProvider.notifier)
                                .toggle(product),
                            onTap: () => context.push(
                              '${AppRoutes.productDetails}/${product.id}',
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final RangeValues priceRange;
  final double minRating;
  final void Function(RangeValues price, double rating) onApply;

  const _FilterSheet({
    required this.priceRange,
    required this.minRating,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RangeValues _price = widget.priceRange;
  late double _rating = widget.minRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.lg,
        right: AppDimens.lg,
        top: AppDimens.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.lg,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: AppTextStyles.h4),
          const SizedBox(height: AppDimens.lg),
          Text(
            'Price Range',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          RangeSlider(
            values: _price,
            min: 0,
            max: 80000,
            divisions: 20,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              'Rs.${_price.start.round()}',
              'Rs.${_price.end.round()}',
            ),
            onChanged: (v) => setState(() => _price = v),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            'Minimum Rating',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [0, 3, 3.5, 4, 4.5].map((r) {
              final selected = _rating == r;
              return ChoiceChip(
                label: Text(r == 0 ? 'Any' : '$r+ \u2605'),
                selected: selected,
                onSelected: (_) => setState(() => _rating = r.toDouble()),
                selectedColor: AppColors.primaryLight,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimens.xl),
          PrimaryButton(
            label: 'Apply Filters',
            onPressed: () {
              widget.onApply(_price, _rating);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
