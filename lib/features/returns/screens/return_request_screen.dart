// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/cloudinary_config.dart';
import '../../../core/data/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../orders/models/order_model.dart';
import '../../orders/providers/orders_provider.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../models/return_model.dart';
import '../providers/returns_provider.dart';

OrderItem? _findItem(List<OrderItem>? items, String productId) {
  if (items == null) return null;
  for (final item in items) {
    if (item.productId == productId) return item;
  }
  return null;
}

class ReturnRequestScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;
  const ReturnRequestScreen({
    super.key,
    required this.orderId,
    required this.productId,
  });

  @override
  ConsumerState<ReturnRequestScreen> createState() =>
      _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _descriptionController = TextEditingController();
  String _reason = returnReasons.first;
  int _quantity = 1;
  bool _submitted = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  final List<String> _imageUrls = [];

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
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await cloudinaryService.uploadImageBytes(
        bytes,
        fileName: picked.name,
        folder: 'returns',
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

  Future<void> _submit() async {
    final order = ref.read(ordersProvider.notifier).getById(widget.orderId);
    final item = _findItem(order?.items, widget.productId);
    if (order == null || item == null) return;

    setState(() => _isSubmitting = true);
    final profile = ref.read(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final request = ReturnRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: widget.orderId,
      userId: uid,
      customerName: profile.name,
      productId: widget.productId,
      productName: item.name,
      quantity: _quantity,
      reason: _reason,
      description: _descriptionController.text.trim(),
      imageUrls: _imageUrls,
      requestedAt: DateTime.now(),
    );

    try {
      await ref.read(returnsProvider.notifier).submit(request);
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit request. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(ordersProvider.notifier).getById(widget.orderId);
    final item = _findItem(order?.items, widget.productId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Return / Refund')),
      body: SafeArea(
        child: _submitted
            ? _buildSuccessState(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item != null)
                      Container(
                        padding: const EdgeInsets.all(AppDimens.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppDimens.lg),

                    Text(
                      'Quantity to Return',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: () => setState(
                            () => _quantity = _quantity > 1 ? _quantity - 1 : 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_quantity', style: AppTextStyles.h4),
                        ),
                        _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: () => setState(
                            () => _quantity =
                                (item != null && _quantity < item.quantity)
                                ? _quantity + 1
                                : _quantity,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.lg),
                    Text(
                      'Reason',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: returnReasons.map((r) {
                        final selected = r == _reason;
                        return ChoiceChip(
                          label: Text(r),
                          selected: selected,
                          onSelected: (_) => setState(() => _reason = r),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppDimens.lg),
                    AppTextField(
                      label: 'Additional Details (optional)',
                      hint: 'Tell us more about the issue',
                      controller: _descriptionController,
                      maxLines: 4,
                    ),

                    const SizedBox(height: AppDimens.md),
                    Text(
                      'Add Photos (optional)',
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

                    const SizedBox(height: AppDimens.xl),
                    PrimaryButton(
                      label: 'Submit Return Request',
                      isLoading: _isSubmitting,
                      onPressed: item == null ? null : _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              'Return Request Submitted',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'We\u2019ll review your request and get back to you within 24-48 hours.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.xl),
            PrimaryButton(
              label: 'Back to Orders',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
