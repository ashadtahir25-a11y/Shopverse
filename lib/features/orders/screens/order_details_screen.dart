import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/product_card.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_status_badge.dart';

const _cancelReasons = [
  'Changed my mind',
  'Ordered by mistake',
  'Found cheaper product',
  'Delivery taking too long',
  'Other',
];

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  void _showCancelSheet(BuildContext context, WidgetRef ref) {
    String selectedReason = _cancelReasons.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppDimens.lg,
            right: AppDimens.lg,
            top: AppDimens.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel Order', style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                'Please tell us why',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (v) => setSheetState(() => selectedReason = v!),
                child: Column(
                  children: _cancelReasons
                      .map(
                        (reason) => RadioListTile<String>(
                          value: reason,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(reason, style: AppTextStyles.bodyMedium),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              PrimaryButton(
                label: 'Confirm Cancellation',
                outlined: true,
                onPressed: () {
                  ref
                      .read(ordersProvider.notifier)
                      .cancelOrder(orderId, selectedReason);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(
      ordersProvider.select(
        (orders) => orders.where((o) => o.id == orderId).isEmpty
            ? null
            : orders.firstWhere((o) => o.id == orderId),
      ),
    );

    if (order == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.date.day}/${order.date.month}/${order.date.year}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppDimens.md),

          PrimaryButton(
            label: 'Track Order',
            outlined: true,
            icon: Icons.local_shipping_outlined,
            onPressed: () => context.push('/orders/${order.id}/track'),
          ),
          const SizedBox(height: AppDimens.lg),

          Text('Items', style: AppTextStyles.h4),
          const SizedBox(height: AppDimens.md),
          ...order.items.map(
            (item) => _OrderItemTile(
              orderId: order.id,
              item: item,
              orderStatus: order.status,
            ),
          ),

          const SizedBox(height: AppDimens.lg),
          _SectionCard(
            title: 'Delivery Address',
            child: Text(
              order.addressSummary,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.md),
          _SectionCard(
            title: 'Payment Method',
            child: Text(
              order.paymentMethodLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.md),
          _SectionCard(
            title: 'Order Summary',
            child: Column(
              children: [
                _SummaryLine(label: 'Subtotal', value: order.subtotal),
                if (order.discount > 0)
                  _SummaryLine(label: 'Discount', value: -order.discount),
                _SummaryLine(label: 'Delivery Fee', value: order.deliveryFee),
                const Divider(height: 20),
                _SummaryLine(label: 'Total', value: order.total, isBold: true),
              ],
            ),
          ),

          if (order.status.isCancellable) ...[
            const SizedBox(height: AppDimens.xl),
            PrimaryButton(
              label: 'Cancel Order',
              outlined: true,
              onPressed: () => _showCancelSheet(context, ref),
            ),
          ],
          const SizedBox(height: AppDimens.xl),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final String orderId;
  final OrderItem item;
  final OrderStatus orderStatus;

  const _OrderItemTile({
    required this.orderId,
    required this.item,
    required this.orderStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ProductImagePlaceholder(
                  category: item.category,
                  seed: item.productId,
                  imageUrl: item.imageUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.variantLabel.isNotEmpty)
                      Text(item.variantLabel, style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity} · Rs. ${item.subtotal.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (orderStatus.isReturnEligible) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/returns/new/$orderId/${item.productId}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                    ),
                    child: const Text('Return / Refund'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: item.reviewed
                        ? null
                        : () => context.push(
                            '/reviews/write/${item.productId}?orderId=$orderId',
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                    ),
                    child: Text(
                      item.reviewed ? 'Reviewed ✓' : 'Write a Review',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  const _SummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${value < 0 ? '-' : ''}Rs. ${value.abs().toStringAsFixed(0)}',
            style: isBold ? style.copyWith(color: AppColors.primary) : style,
          ),
        ],
      ),
    );
  }
}
