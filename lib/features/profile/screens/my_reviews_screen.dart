import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../reviews/models/review_model.dart';

/// The signed-in customer's own reviews (every status, so they can see
/// which are still waiting for approval). Allowed by the existing
/// `reviews` rule: `resource.data.userId == request.auth.uid`.
final myReviewsProvider = StreamProvider.autoDispose<List<Review>>((ref) {
  final uid = FirebaseStatus.isInitialized ? FirebaseAuth.instance.currentUser?.uid : null;
  if (uid == null) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Review.fromFirestore(d.id, d.data())).toList()..sort((a, b) => b.date.compareTo(a.date)));
});

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  Color _color(String status) => switch (status) {
        'approved' => AppColors.success,
        'rejected' => AppColors.error,
        _ => AppColors.warning,
      };

  String _label(String status) => switch (status) {
        'approved' => 'Published',
        'rejected' => 'Rejected',
        _ => 'Awaiting approval',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Reviews')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn\u2019t load your reviews', style: AppTextStyles.bodyMedium)),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_border_rounded, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No reviews yet', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('Review a delivered order to see it here', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.md),
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = reviews[i];
              final c = _color(r.status);
              return Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(r.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(_label(r.status), style: AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RatingBarIndicator(
                      rating: r.rating.toDouble(),
                      itemCount: 5,
                      itemSize: 16,
                      unratedColor: AppColors.border,
                      itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: AppColors.star),
                    ),
                    if (r.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    Text('${r.date.day}/${r.date.month}/${r.date.year}', style: AppTextStyles.caption),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
