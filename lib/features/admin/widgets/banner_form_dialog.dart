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
import '../../home/widgets/banner_model.dart';
import '../providers/admin_banners_provider.dart';

/// Shows the Add/Edit Banner dialog. Pass an existing [banner] to edit
/// it, or omit it to create a new one.
Future<void> showBannerFormDialog(BuildContext context, {BannerData? banner}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _BannerFormDialog(banner: banner),
  );
}

class _BannerFormDialog extends ConsumerStatefulWidget {
  final BannerData? banner;
  const _BannerFormDialog({this.banner});

  @override
  ConsumerState<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<_BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _ctaController;
  late final TextEditingController _sortOrderController;

  String _iconKey = 'tag';
  String _gradientKey = 'purple';
  String? _imageUrl;
  bool _isUploadingImage = false;
  String? _targetCategoryId;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleController = TextEditingController(text: b?.title ?? '');
    _subtitleController = TextEditingController(text: b?.subtitle ?? '');
    _ctaController = TextEditingController(text: b?.ctaLabel ?? 'Shop Now');
    _sortOrderController = TextEditingController(
      text: (b?.sortOrder ?? 0).toString(),
    );
    _iconKey = b?.iconKey ?? 'tag';
    _gradientKey = b?.gradientKey ?? 'purple';
    _imageUrl = b?.imageUrl;
    _targetCategoryId = b?.targetCategoryId;
    _isActive = b?.isActive ?? true;
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
      maxWidth: 1600,
      maxHeight: 900,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await cloudinaryService.uploadImageBytes(
        bytes,
        fileName: picked.name,
        folder: 'banners',
      );
      setState(() => _imageUrl = url);
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

    setState(() => _isSaving = true);
    try {
      final banner = BannerData(
        id: widget.banner?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        ctaLabel: _ctaController.text.trim(),
        iconKey: _iconKey,
        gradientKey: _gradientKey,
        imageUrl: _imageUrl,
        targetCategoryId: _targetCategoryId,
        isActive: _isActive,
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
      );
      await adminBannersService.saveBanner(banner);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Banner updated' : 'Banner created'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save banner. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final gradient = BannerData.gradients[_gradientKey]!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Banner' : 'Add Banner',
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
                      // Live preview
                      Container(
                        height: 100,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
                          gradient: _imageUrl == null
                              ? LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_imageUrl != null)
                              Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: AppColors.skeleton),
                              ),
                            if (_imageUrl != null)
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
                            if (_imageUrl == null)
                              Positioned(
                                right: -6,
                                bottom: -6,
                                child: Icon(
                                  BannerData.icons[_iconKey],
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(AppDimens.md),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _titleController.text.isEmpty
                                          ? 'Title'
                                          : _titleController.text,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _subtitleController.text.isEmpty
                                          ? 'Subtitle'
                                          : _subtitleController.text,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.lg),

                      AppTextField(
                        label: 'Title',
                        hint: 'e.g. Season Sale',
                        controller: _titleController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Subtitle',
                        hint: 'e.g. Up to 40% off on electronics',
                        controller: _subtitleController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Button Label',
                        hint: 'e.g. Shop Now',
                        controller: _ctaController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      Text(
                        'Custom Image (optional)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload your own photo instead of the icon + gradient style below.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMd,
                                    ),
                                    child: Image.network(
                                      _imageUrl!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
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
                                          setState(() => _imageUrl = null),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploadingImage
                                  ? null
                                  : _uploadImage,
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                _imageUrl == null
                                    ? 'Upload Image'
                                    : 'Replace Image',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.lg),

                      Text(
                        'Icon & Gradient ${_imageUrl != null ? '(unused while a custom image is set)' : ''}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BannerData.icons.entries.map((entry) {
                          final selected = _iconKey == entry.key;
                          return GestureDetector(
                            onTap: () => setState(() => _iconKey = entry.key),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 18,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimens.md),

                      Text(
                        'Gradient',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BannerData.gradients.entries.map((entry) {
                          final selected = _gradientKey == entry.key;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _gradientKey = entry.key),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: entry.value,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd,
                                ),
                                border: selected
                                    ? Border.all(
                                        color: AppColors.textPrimary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimens.lg),

                      Text(
                        'Links To (optional)',
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
                        data: (categories) => DropdownButtonFormField<String?>(
                          initialValue: _targetCategoryId,
                          hint: const Text('No link (just visual)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No link (just visual)'),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _targetCategoryId = v),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: 'Sort Order (lower shows first)',
                        hint: '0',
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
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
                          'Visible on Home screen when on',
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
                label: _isEditing ? 'Save Changes' : 'Create Banner',
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
