// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_router.dart';
import 'category_model.dart';
import 'category_provider.dart';
import '../../core/widgets/surface_card.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Couldn\u2019t load categories',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (categories) => ListView.separated(
          padding: const EdgeInsets.all(AppDimens.md),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final ProductCategory cat = categories[i];
            return _CategoryExpansionTile(category: cat);
          },
        ),
      ),
    );
  }
}

class _CategoryExpansionTile extends StatelessWidget {
  final ProductCategory category;
  const _CategoryExpansionTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusLg)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusLg)),
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            category.name,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${category.subcategories.length} subcategories',
            style: AppTextStyles.caption,
          ),
          onExpansionChanged: (_) {},
          children: [
            ...category.subcategories.map(
              (sub) => ListTile(
                contentPadding: const EdgeInsets.only(left: 70, right: 16),
                title: Text(sub, style: AppTextStyles.bodyMedium),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onTap: () => context.push(
                  '${AppRoutes.productListing}?category=${category.id}&title=$sub',
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
