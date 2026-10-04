import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../checkout/models/coupon_model.dart';
import '../providers/admin_coupons_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import '../widgets/coupon_form_dialog.dart';

class AdminCouponsScreen extends StatelessWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      section: 'Coupons',
      child: const AdminShell(activeLabel: 'Coupons', child: _CouponsContent()),
    );
  }
}

class _CouponsContent extends ConsumerStatefulWidget {
  const _CouponsContent();

  @override
  ConsumerState<_CouponsContent> createState() => _CouponsContentState();
}

class _CouponsContentState extends ConsumerState<_CouponsContent> {
  final _searchController = TextEditingController();

  Future<void> _confirmDelete(BuildContext context, Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: const Text('Delete Coupon'),
        content: Text(
          'Are you sure you want to permanently delete "${coupon.code}"?',
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
      await adminCouponsService.deleteCoupon(coupon.code);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Coupon deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(adminCouponsProvider);
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
                    Text('Coupons', style: AppTextStyles.h2),
                    ElevatedButton.icon(
                      onPressed: () => showCouponFormDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Coupon'),
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
                      hintText: 'Search coupon code...',
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
                  child: couponsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load coupons',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (coupons) {
                      final filtered = query.isEmpty
                          ? coupons
                          : coupons
                                .where(
                                  (c) => c.code.toLowerCase().contains(query),
                                )
                                .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No coupons found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _CouponRow(
                          coupon: filtered[i],
                          onEdit: () => showCouponFormDialog(
                            context,
                            coupon: filtered[i],
                          ),
                          onDelete: () => _confirmDelete(context, filtered[i]),
                          onToggleActive: () => adminCouponsService.setActive(
                            filtered[i],
                            !filtered[i].active,
                          ),
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

class _CouponRow extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CouponRow({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  bool get _isExpired => DateTime.now().isAfter(coupon.expiry);

  @override
  Widget build(BuildContext context) {
    final statusLabel = _isExpired
        ? 'expired'
        : (coupon.active ? 'active' : 'inactive');
    final statusColor = _isExpired
        ? AppColors.textMuted
        : (coupon.active ? AppColors.success : AppColors.warning);
    final valueLabel = coupon.type == CouponType.percentage
        ? '${coupon.value.toStringAsFixed(0)}% off'
        : 'Rs. ${coupon.value.toStringAsFixed(0)} off';

    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      coupon.code,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$valueLabel · Min Rs. ${coupon.minOrder.toStringAsFixed(0)} · Expires ${coupon.expiry.day}/${coupon.expiry.month}/${coupon.expiry.year}',
                  style: AppTextStyles.caption,
                ),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    coupon.active
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_outlined,
                    size: 26,
                    color: coupon.active
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  tooltip: coupon.active ? 'Deactivate' : 'Activate',
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
                children: [info, const SizedBox(height: 8), actions],
              );
            }

            return Row(
              children: [
                Expanded(child: info),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
