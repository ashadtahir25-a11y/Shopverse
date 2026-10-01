import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
        OrderStatus.pending => AppColors.warning,
        OrderStatus.confirmed || OrderStatus.processing || OrderStatus.packed => AppColors.info,
        OrderStatus.shipped || OrderStatus.outForDelivery => AppColors.primary,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
        OrderStatus.returned || OrderStatus.refunded => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(color: _color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
