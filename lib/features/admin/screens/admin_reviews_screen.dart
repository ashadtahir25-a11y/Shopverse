import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/full_image_viewer.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../reviews/models/review_model.dart';
import '../providers/admin_reviews_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminGuard(
      child: AdminShell(activeLabel: 'Reviews', child: _ReviewsContent()),
    );
  }
}

class _ReviewsContent extends ConsumerStatefulWidget {
  const _ReviewsContent();

  @override
  ConsumerState<_ReviewsContent> createState() => _ReviewsContentState();
}

class _ReviewsContentState extends ConsumerState<_ReviewsContent> {
  String? _statusFilter = 'pending';

  Future<void> _confirmDelete(BuildContext context, Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: const Text('Delete Review'),
        content: const Text(
          'Are you sure you want to permanently delete this review?',
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
      await adminReviewsService.delete(review.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewsProvider);

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
                Text('Reviews', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.md),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Pending',
                        selected: _statusFilter == 'pending',
                        onTap: () => setState(() => _statusFilter = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Approved',
                        selected: _statusFilter == 'approved',
                        onTap: () => setState(() => _statusFilter = 'approved'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Rejected',
                        selected: _statusFilter == 'rejected',
                        onTap: () => setState(() => _statusFilter = 'rejected'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'All',
                        selected: _statusFilter == null,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: reviewsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load reviews',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (reviews) {
                      final filtered = _statusFilter == null
                          ? reviews
                          : reviews
                                .where((r) => r.status == _statusFilter)
                                .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No reviews here',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ReviewRow(
                          review: filtered[i],
                          onApprove: () => adminReviewsService.setStatus(
                            filtered[i].id,
                            'approved',
                          ),
                          onReject: () => adminReviewsService.setStatus(
                            filtered[i].id,
                            'rejected',
                          ),
                          onDelete: () => _confirmDelete(context, filtered[i]),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final Review review;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _ReviewRow({
    required this.review,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get _statusColor => switch (review.status) {
    'approved' => AppColors.success,
    'rejected' => AppColors.error,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  avatarUrl: review.userAvatarUrl,
                  name: review.userName,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(review.productName, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    review.status,
                    style: AppTextStyles.caption.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: review.rating.toDouble(),
              itemCount: 5,
              itemSize: 16,
              unratedColor: AppColors.border,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star_rounded, color: AppColors.star),
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                review.text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () =>
                        showFullImageViewer(context, review.imageUrls[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      child: Image.network(
                        review.imageUrls[i],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (review.status != 'approved')
                  OutlinedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    label: const Text('Approve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                if (review.status != 'rejected')
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
