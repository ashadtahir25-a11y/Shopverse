import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../orders/models/order_model.dart';
import '../../orders/widgets/order_status_badge.dart';
import '../providers/admin_orders_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import '../widgets/order_status_dialog.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminGuard(
      child: AdminShell(activeLabel: 'Orders', child: _OrdersContent()),
    );
  }
}

class _OrdersContent extends ConsumerStatefulWidget {
  const _OrdersContent();

  @override
  ConsumerState<_OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends ConsumerState<_OrdersContent> {
  final _searchController = TextEditingController();
  OrderStatus? _statusFilter;

  static const _filterChips = [
    null,
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
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
                Text('Orders', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.md),
                SizedBox(
                  width: isNarrow ? double.infinity : 340,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search order #, customer name/email...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterChips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final status = _filterChips[i];
                      final selected = _statusFilter == status;
                      return ChoiceChip(
                        label: Text(status?.label ?? 'All'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
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
                    },
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: ordersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load orders',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (orders) {
                      var filtered = orders;
                      if (_statusFilter != null) {
                        filtered = filtered
                            .where((o) => o.status == _statusFilter)
                            .toList();
                      }
                      if (query.isNotEmpty) {
                        filtered = filtered
                            .where(
                              (o) =>
                                  o.orderNumber.toLowerCase().contains(query) ||
                                  o.customerName.toLowerCase().contains(
                                    query,
                                  ) ||
                                  o.customerEmail.toLowerCase().contains(query),
                            )
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No orders found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _OrderRow(
                          order: filtered[i],
                          onTap: () =>
                              showOrderStatusDialog(context, filtered[i]),
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

class _OrderRow extends StatelessWidget {
  final AppOrder order;
  final VoidCallback onTap;

  const _OrderRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final header = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    order.orderNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    '${order.date.day}/${order.date.month}/${order.date.year} · ${order.items.length} item(s)',
                    style: AppTextStyles.caption,
                  ),
                ],
              );
              final trailing = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrderStatusBadge(status: order.status),
                  const SizedBox(height: 6),
                  Text(
                    'Rs. ${order.total.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OrderStatusBadge(status: order.status),
                        const Spacer(),
                        Text(
                          'Rs. ${order.total.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: header),
                  trailing,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
