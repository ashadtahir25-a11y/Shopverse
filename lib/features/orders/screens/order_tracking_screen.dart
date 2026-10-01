import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

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

    final flow = OrderStatusX.trackingFlow;
    final isCancelled = order.status == OrderStatus.cancelled;
    final currentIndex = isCancelled ? -1 : flow.indexOf(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Track Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isCancelled
                              ? 'This order was cancelled'
                              : 'Current status: ${order.status.label}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xl),

            if (isCancelled)
              _TimelineTile(
                title: 'Order Cancelled',
                subtitle: order.history.isNotEmpty
                    ? (order.history.last.note ?? '')
                    : '',
                timestamp: order.history.isNotEmpty
                    ? order.history.last.timestamp
                    : order.date,
                isDone: true,
                isError: true,
                isLast: true,
              )
            else
              ...List.generate(flow.length, (i) {
                final step = flow[i];
                final isDone = i <= currentIndex;
                final historyEntry =
                    order.history.where((h) => h.status == step).isNotEmpty
                    ? order.history.firstWhere((h) => h.status == step)
                    : null;
                return _TimelineTile(
                  title: step.label,
                  subtitle: historyEntry?.note ?? '',
                  timestamp: historyEntry?.timestamp,
                  isDone: isDone,
                  isLast: i == flow.length - 1,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final bool isDone;
  final bool isLast;
  final bool isError;

  const _TimelineTile({
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.isDone,
    required this.isLast,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? AppColors.error
        : (isDone ? AppColors.success : AppColors.border);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  isError ? Icons.close_rounded : Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDone || isError
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      '${timestamp!.day}/${timestamp!.month}/${timestamp!.year} · ${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.caption,
                    ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
