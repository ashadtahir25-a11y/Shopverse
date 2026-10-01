import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/surface_card.dart';
import '../../product/models/product_model.dart';
import '../providers/admin_products_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import '../widgets/product_form_dialog.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminGuard(
      child: AdminShell(activeLabel: 'Products', child: _ProductsContent()),
    );
  }
}

class _ProductsContent extends ConsumerStatefulWidget {
  const _ProductsContent();

  @override
  ConsumerState<_ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends ConsumerState<_ProductsContent> {
  final _searchController = TextEditingController();

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await adminProductsService.deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final query = _searchController.text.trim().toLowerCase();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final padding = isNarrow ? AppDimens.md : AppDimens.xl;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimens.md,
                  runSpacing: AppDimens.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Products', style: AppTextStyles.h2),
                    ElevatedButton.icon(
                      onPressed: () => showProductFormDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                SizedBox(
                  width: isNarrow ? double.infinity : 340,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: productsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load products',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (products) {
                      final filtered = query.isEmpty
                          ? products
                          : products
                                .where(
                                  (p) =>
                                      p.name.toLowerCase().contains(query) ||
                                      p.sku.toLowerCase().contains(query),
                                )
                                .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No products found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ProductRow(
                          product: filtered[i],
                          onEdit: () => showProductFormDialog(
                            context,
                            product: filtered[i],
                          ),
                          onDelete: () => _confirmDelete(context, filtered[i]),
                          onTogglePublish: () =>
                              adminProductsService.setPublishStatus(
                                filtered[i].id,
                                filtered[i].status != 'published',
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  Color get _statusColor => switch (product.status) {
    'published' => AppColors.success,
    'draft' => AppColors.warning,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final thumbnail = ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ProductImagePlaceholder(
                  category: product.category,
                  seed: product.id,
                  imageUrl: product.images.isNotEmpty
                      ? product.images.first
                      : null,
                ),
              ),
            );
            final nameAndSku = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.sku} · Stock: ${product.stock}',
                  style: AppTextStyles.caption,
                ),
              ],
            );
            final statusBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.status,
                style: AppTextStyles.caption.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
            final price = Text(
              'Rs. ${product.price.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    product.status == 'published'
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  tooltip: product.status == 'published'
                      ? 'Unpublish'
                      : 'Publish',
                  onPressed: onTogglePublish,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            );

            if (constraints.maxWidth < 520) {
              // Compact 2-row layout for narrow (mobile drawer) admin views.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      thumbnail,
                      const SizedBox(width: 12),
                      Expanded(child: nameAndSku),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      statusBadge,
                      const SizedBox(width: 10),
                      price,
                      const Spacer(),
                      actions,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                thumbnail,
                const SizedBox(width: 12),
                Expanded(child: nameAndSku),
                statusBadge,
                const SizedBox(width: 12),
                price,
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
