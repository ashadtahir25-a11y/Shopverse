// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../categories/category_model.dart';
import '../providers/admin_categories_provider.dart';

/// Shows the Add/Edit Category dialog. Pass an existing [category] to
/// edit it, or omit it to create a new one.
Future<void> showCategoryFormDialog(
  BuildContext context, {
  ProductCategory? category,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CategoryFormDialog(category: category),
  );
}

class _CategoryFormDialog extends StatefulWidget {
  final ProductCategory? category;
  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  final _subcategoryController = TextEditingController();

  String _iconKey = 'other';
  List<String> _subcategories = [];
  bool _isActive = true;
  bool _isSaving = false;
  bool _idEditedManually = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _idController = TextEditingController(text: c?.id ?? '');
    _iconKey = c?.iconKey ?? 'other';
    _subcategories = List<String>.from(c?.subcategories ?? []);
    _isActive = c?.isActive ?? true;
    _idEditedManually = _isEditing; // don't auto-slug over an existing id
  }

  String _slugify(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');

  void _addSubcategory() {
    final value = _subcategoryController.text.trim();
    if (value.isEmpty || _subcategories.contains(value)) return;
    setState(() {
      _subcategories.add(value);
      _subcategoryController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category ID is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (!_isEditing) {
        final exists = await adminCategoriesService.idExists(id);
        if (exists) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'A category with ID "$id" already exists — pick a different one',
              ),
            ),
          );
          return;
        }
      }

      final category = ProductCategory(
        id: id,
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        subcategories: _subcategories,
        isActive: _isActive,
      );
      await adminCategoriesService.saveCategory(category);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Category updated' : 'Category created'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save category. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Category' : 'Add Category',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Icon',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ProductCategory.icons.entries.map((entry) {
                          final selected = _iconKey == entry.key;
                          return GestureDetector(
                            onTap: () => setState(() => _iconKey = entry.key),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd,
                                ),
                                border: selected
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                entry.value,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 20,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Category Name',
                        hint: 'e.g. Sports & Outdoors',
                        controller: _nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onChanged: (v) {
                          if (!_idEditedManually) {
                            _idController.text = _slugify(v);
                          }
                        },
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label:
                            'Category ID (used internally, can\u2019t change once products use it)',
                        hint: 'e.g. sports',
                        controller: _idController,
                        enabled: !_isEditing,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onChanged: (_) => _idEditedManually = true,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      Text(
                        'Subcategories',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subcategories
                            .map(
                              (sub) => Chip(
                                label: Text(sub),
                                onDeleted: () =>
                                    setState(() => _subcategories.remove(sub)),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subcategoryController,
                              onSubmitted: (_) => _addSubcategory(),
                              decoration: const InputDecoration(
                                hintText: 'Add a subcategory...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: _addSubcategory,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.md),

                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Active',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Visible to customers when on',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Create Category',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
