import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/product_card.dart';
import 'models/cart_item_model.dart';
import 'providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    const deliveryFee = 250.0;
    final total = cartItems.isEmpty ? 0.0 : subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Cart (${cartItems.length})')),
      body: cartItems.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimens.md),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _CartItemTile(item: cartItems[i]),
                  ),
                ),
                _buildSummaryBar(context, subtotal, deliveryFee, total),
              ],
            ),
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    double subtotal,
    double deliveryFee,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.md,
        AppDimens.md,
        AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Subtotal', value: subtotal),
            _SummaryRow(label: 'Delivery Fee', value: deliveryFee),
            const Divider(height: 20),
            _SummaryRow(label: 'Total', value: total, isBold: true),
            const SizedBox(height: AppDimens.md),
            PrimaryButton(
              label: 'Proceed to Checkout',
              onPressed: () => context.push(AppRoutes.checkoutAddress),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _SummaryRow({
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
            'Rs. ${value.toStringAsFixed(0)}',
            style: isBold ? style.copyWith(color: AppColors.primary) : style,
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: ProductImagePlaceholder(
              category: item.product.category,
              seed: item.product.id,
              imageUrl: item.product.images.isNotEmpty
                  ? item.product.images.first
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.variantLabel, style: AppTextStyles.caption),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs. ${item.product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price.copyWith(fontSize: 15),
                    ),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: () => notifier.decrement(item.id),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: () => notifier.increment(item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            onPressed: () {
              // A leftover "Added to cart — View Cart" toast makes no
              // sense once the item it referred to is gone (or while
              // already on the cart screen), so dismiss it on removal.
              ScaffoldMessenger.of(context).clearSnackBars();
              notifier.remove(item.id);
            },
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('Your cart is empty', style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            'Add products to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
