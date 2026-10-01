import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../categories/category_model.dart';
import '../providers/admin_categories_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import '../widgets/category_form_dialog.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminGuard(
      child: AdminShell(activeLabel: 'Categories', child: _CategoriesContent()),
    );
  }
}

class _CategoriesContent extends ConsumerStatefulWidget {
  const _CategoriesContent();

  @override
  ConsumerState<_CategoriesContent> createState() => _CategoriesContentState();
}

class _CategoriesContentState extends ConsumerState<_CategoriesContent> {
  final _searchController = TextEditingController();

  Future<void> _confirmDelete(
    BuildContext context,
    ProductCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to permanently delete "${category.name}"? '
          'Products already using this category will keep the old category value but won\u2019t be filterable by it anymore.',
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
      await adminCategoriesService.deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);
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
                    Text('Categories', style: AppTextStyles.h2),
                    ElevatedButton.icon(
                      onPressed: () => showCategoryFormDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Category'),
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
                      hintText: 'Search categories...',
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
                  child: categoriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load categories',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (categories) {
                      final filtered = query.isEmpty
                          ? categories
                          : categories
                                .where(
                                  (c) => c.name.toLowerCase().contains(query),
                                )
                                .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No categories found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _CategoryRow(
                          category: filtered[i],
                          onEdit: () => showCategoryFormDialog(
                            context,
                            category: filtered[i],
                          ),
                          onDelete: () => _confirmDelete(context, filtered[i]),
                          onToggleActive: () => adminCategoriesService
                              .setActive(filtered[i], !filtered[i].isActive),
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

class _CategoryRow extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final icon = Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(category.icon, color: AppColors.primary, size: 20),
            );
            final nameAndCount = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${category.subcategories.length} subcategories · ID: ${category.id}',
                  style: AppTextStyles.caption,
                ),
              ],
            );
            final statusBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (category.isActive
                            ? AppColors.success
                            : AppColors.textMuted)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.isActive ? 'active' : 'inactive',
                style: AppTextStyles.caption.copyWith(
                  color: category.isActive
                      ? AppColors.success
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    category.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  tooltip: category.isActive ? 'Deactivate' : 'Activate',
                  onPressed: onToggleActive,
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

            if (constraints.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: nameAndCount),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [statusBadge, const Spacer(), actions]),
                ],
              );
            }

            return Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: nameAndCount),
                statusBadge,
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
