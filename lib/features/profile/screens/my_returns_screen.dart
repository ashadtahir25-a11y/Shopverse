// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../returns/models/return_model.dart';
import '../../returns/providers/returns_provider.dart';

/// The customer's own return/refund requests and where each one stands.
/// (New requests are started from an order's details screen.)
class MyReturnsScreen extends ConsumerWidget {
  const MyReturnsScreen({super.key});

  Color _color(ReturnStatus s) => switch (s) {
        ReturnStatus.refunded => AppColors.success,
        ReturnStatus.rejected => AppColors.error,
        ReturnStatus.requested || ReturnStatus.underReview => AppColors.warning,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returns = ref.watch(returnsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Returns')),
      body: returns.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_return_outlined, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('No return requests', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      'To return an item, open it from My Orders and tap "Return / Refund".',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimens.md),
              itemCount: returns.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = returns[i];
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
                            child: Text(r.status.label, style: AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Qty ${r.quantity} · ${r.reason}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Requested ${r.requestedAt.day}/${r.requestedAt.month}/${r.requestedAt.year}', style: AppTextStyles.caption),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
