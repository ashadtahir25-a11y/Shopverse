import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/product_card.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/product_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final List<String> _recentSearches = [
    'Wireless headphones',
    'Sneakers',
    'Smartwatch',
  ];
  static const List<String> _popularSearches = [
    'Nova X1',
    'Leather bag',
    'Serum',
    'Running jacket',
  ];

  List _resultsFrom(List source) {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return [];
    return source.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _controller.text = query;
      if (!_recentSearches.contains(query)) _recentSearches.insert(0, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final source = productsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const [],
    );
    final results = _resultsFrom(source);
    final isSearching = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: _runSearch,
          decoration: InputDecoration(
            hintText: 'Search products, brands, SKU...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _controller.clear()),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: !isSearching
            ? ListView(
                children: [
                  if (_recentSearches.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Searches', style: AppTextStyles.h4),
                        TextButton(
                          onPressed: () =>
                              setState(() => _recentSearches.clear()),
                          child: Text('Clear', style: AppTextStyles.link),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches
                          .map(
                            (s) => _SearchChip(
                              label: s,
                              icon: Icons.history_rounded,
                              onTap: () => _runSearch(s),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                  ],
                  Text('Popular Searches', style: AppTextStyles.h4),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularSearches
                        .map(
                          (s) => _SearchChip(
                            label: s,
                            icon: Icons.trending_up_rounded,
                            onTap: () => _runSearch(s),
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            : results.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text('No products found', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      'Try different keywords or browse categories',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                itemCount: results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.56,
                ),
                itemBuilder: (context, i) {
                  final product = results[i];
                  final wishlist = ref.watch(wishlistProvider);
                  return ProductCard(
                    product: product,
                    isWishlisted: wishlist.any((p) => p.id == product.id),
                    onWishlistTap: () =>
                        ref.read(wishlistProvider.notifier).toggle(product),
                    onTap: () => context.push(
                      '${AppRoutes.productDetails}/${product.id}',
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SearchChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
