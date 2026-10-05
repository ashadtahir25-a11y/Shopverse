// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/cloudinary_config.dart';
import '../../../core/data/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../orders/providers/orders_provider.dart';
import '../../product/providers/product_provider.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../models/review_model.dart';
import '../providers/reviews_provider.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? orderId;
  const WriteReviewScreen({super.key, required this.productId, this.orderId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _textController = TextEditingController();
  double _rating = 5;
  final List<String> _imageUrls = [];
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

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
        folder: 'reviews',
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
    final product = ref.read(productByIdProvider(widget.productId)).value;
    if (product == null) return;
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a few words about the product'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final profile = ref.read(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final review = Review(
      id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      userId: uid,
      userName: profile.name,
      userAvatarUrl: profile.avatarUrl,
      rating: _rating.round(),
      text: _textController.text.trim(),
      imageUrls: _imageUrls,
      date: DateTime.now(),
      // New reviews wait for admin approval before appearing publicly —
      // see the Admin Dashboard's Reviews screen.
      status: 'pending',
    );

    try {
      await reviewsService.submit(review);
      if (widget.orderId != null) {
        ref
            .read(ordersProvider.notifier)
            .markItemReviewed(widget.orderId!, widget.productId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Review submitted — it\u2019ll appear once approved. Thank you!',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productByIdProvider(widget.productId)).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Write a Review')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product != null) Text(product.name, style: AppTextStyles.h4),
              const SizedBox(height: AppDimens.lg),
              Center(
                child: Column(
                  children: [
                    Text(
                      'How would you rate this product?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RatingBar.builder(
                      initialRating: 5,
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 40,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star_rounded, color: AppColors.star),
                      onRatingUpdate: (rating) =>
                          setState(() => _rating = rating),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              Text(
                'Your Review',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this product...',
                ),
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
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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
                label: 'Submit Review',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppDimens.md),
            ],
          ),
        ),
      ),
    );
  }
}
