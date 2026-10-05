// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/cloudinary_config.dart';
import '../../../core/data/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../categories/category_provider.dart';
import '../../product/models/product_model.dart';
import '../providers/admin_products_provider.dart';

/// Shows the Add/Edit Product dialog. Pass an existing [product] to edit
/// it, or omit it to create a new one.
Future<void> showProductFormDialog(BuildContext context, {Product? product}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ProductFormDialog(product: product),
  );
}

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _skuController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;

  String? _categoryId;
  List<String> _imageUrls = [];
  bool _isFeatured = false;
  bool _isBestSeller = false;
  bool _isNewArrival = false;
  String _status = 'published';
  bool _isSaving = false;
  bool _isUploadingImage = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _originalPriceController = TextEditingController(
      text: p?.originalPrice != null
          ? p!.originalPrice!.toStringAsFixed(0)
          : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '10',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _categoryId = p?.category;
    _imageUrls = List<String>.from(p?.images ?? []);
    _isFeatured = p?.isFeatured ?? false;
    _isBestSeller = p?.isBestSeller ?? false;
    _isNewArrival = p?.isNewArrival ?? false;
    _status = p?.status ?? 'published';
  }

  Future<void> _uploadImage() async {
    if (!CloudinaryConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cloudinary isn\u2019t configured yet — see lib/core/config/cloudinary_config.dart',
          ),
        ),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await cloudinaryService.uploadImageBytes(
        bytes,
        fileName: picked.name,
        folder: 'products',
      );
      setState(() => _imageUrls.add(url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        sku: _skuController.text.trim(),
        category: _categoryId!,
        images: _imageUrls,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        originalPrice: _originalPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_originalPriceController.text.trim()),
        rating: widget.product?.rating ?? 0,
        reviewCount: widget.product?.reviewCount ?? 0,
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        description: _descriptionController.text.trim(),
        variants: widget.product?.variants ?? const [],
        isFeatured: _isFeatured,
        isBestSeller: _isBestSeller,
        isNewArrival: _isNewArrival,
        status: _status,
      );

      await adminProductsService.saveProduct(product);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Product updated' : 'Product created'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save product. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Product' : 'Add Product',
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
                      // Images
                      Text(
                        'Images',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._imageUrls.map(
                            (url) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd,
                                  ),
                                  child: Image.network(
                                    url,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 72,
                                              height: 72,
                                              color: AppColors.skeleton,
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: AppColors.textMuted,
                                                size: 20,
                                              ),
                                            ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () =>
                                        setState(() => _imageUrls.remove(url)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _uploadImage,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd,
                                ),
                              ),
                              child: _isUploadingImage
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Product Name',
                        hint: 'e.g. AeroFit Wireless Headphones',
                        controller: _nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimens.md),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Brand',
                              hint: 'e.g. SoundWave',
                              controller: _brandController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppDimens.md),
                          Expanded(
                            child: AppTextField(
                              label: 'SKU',
                              hint: 'e.g. SW-AERO-BLK',
                              controller: _skuController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.md),

                      Text(
                        'Category',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      categoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          'Couldn\u2019t load categories',
                          style: AppTextStyles.caption,
                        ),
                        data: (categories) => DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          hint: const Text('Select a category'),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Price (Rs.)',
                              hint: '0',
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  (v == null ||
                                      double.tryParse(v.trim()) == null)
                                  ? 'Enter a valid price'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppDimens.md),
                          Expanded(
                            child: AppTextField(
                              label: 'Original Price (optional)',
                              hint: 'For discounts',
                              controller: _originalPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Stock Quantity',
                        hint: '0',
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || int.tryParse(v.trim()) == null)
                            ? 'Enter a valid number'
                            : null,
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Description',
                        hint: 'Describe the product...',
                        controller: _descriptionController,
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      Text(
                        'Flags',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Featured'),
                            selected: _isFeatured,
                            onSelected: (v) => setState(() => _isFeatured = v),
                          ),
                          FilterChip(
                            label: const Text('Best Seller'),
                            selected: _isBestSeller,
                            onSelected: (v) =>
                                setState(() => _isBestSeller = v),
                          ),
                          FilterChip(
                            label: const Text('New Arrival'),
                            selected: _isNewArrival,
                            onSelected: (v) =>
                                setState(() => _isNewArrival = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.md),

                      Text(
                        'Status',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'published',
                            label: Text('Published'),
                          ),
                          ButtonSegment(value: 'draft', label: Text('Draft')),
                          ButtonSegment(
                            value: 'archived',
                            label: Text('Archived'),
                          ),
                        ],
                        selected: {_status},
                        onSelectionChanged: (s) =>
                            setState(() => _status = s.first),
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
                label: _isEditing ? 'Save Changes' : 'Create Product',
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
