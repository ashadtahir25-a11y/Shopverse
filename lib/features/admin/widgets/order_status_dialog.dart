import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../orders/models/order_model.dart';
import '../../orders/widgets/order_status_badge.dart';
import '../providers/admin_orders_provider.dart';

Future<void> showOrderStatusDialog(BuildContext context, AppOrder order) {
  return showDialog(
    context: context,
    builder: (context) => _OrderStatusDialog(order: order),
  );
}

class _OrderStatusDialog extends StatefulWidget {
  final AppOrder order;
  const _OrderStatusDialog({required this.order});

  @override
  State<_OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<_OrderStatusDialog> {
  late OrderStatus _selected = widget.order.status;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_selected == widget.order.status) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await adminOrdersService.updateStatus(widget.order, _selected);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated to ${_selected.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update order. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(order.orderNumber, style: AppTextStyles.h4),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Customer', value: order.customerName),
                    _InfoRow(label: 'Email', value: order.customerEmail),
                    _InfoRow(
                      label: 'Date',
                      value:
                          '${order.date.day}/${order.date.month}/${order.date.year}',
                    ),
                    _InfoRow(label: 'Payment', value: order.paymentMethodLabel),
                    _InfoRow(label: 'Address', value: order.addressSummary),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      'Items',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name}${item.variantLabel.isNotEmpty ? ' (${item.variantLabel})' : ''} × ${item.quantity}',
                                style: AppTextStyles.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Rs. ${item.subtotal.toStringAsFixed(0)}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Rs. ${order.total.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.lg),

                    Row(
                      children: [
                        Text(
                          'Current status:',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OrderStatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      'Update Status',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: OrderStatus.values.map((status) {
                        final selected = _selected == status;
                        return ChoiceChip(
                          label: Text(status.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _selected = status),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: PrimaryButton(
                label: 'Save',
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
