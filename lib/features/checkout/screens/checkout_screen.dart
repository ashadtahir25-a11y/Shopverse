import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/models/order_model.dart';
import '../../orders/providers/orders_provider.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../providers/address_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/coupon_provider.dart';
import '../models/coupon_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponController = TextEditingController();
  String? _couponError;
  bool _isPlacingOrder = false;

  void _applyCoupon(double subtotal, List<Coupon> availableCoupons) {
    final (coupon, error) = validateCoupon(
      _couponController.text,
      subtotal,
      availableCoupons,
    );
    setState(() => _couponError = error);
    if (coupon != null) {
      ref.read(checkoutProvider.notifier).applyCoupon(coupon);
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    // TODO(phase-6): POST /api/checkout/validate then POST /api/orders.
    // Backend re-validates price/stock/coupon/tax/shipping and returns the
    // authoritative total before the order is created (PRD §66).
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final cartItems = ref.read(cartProvider);
    final subtotal = ref.read(cartSubtotalProvider);
    final checkout = ref.read(checkoutProvider);
    final addresses = ref.read(addressProvider);
    final selectedId = ref.read(selectedAddressIdProvider);
    final selectedAddress = addresses.where((a) => a.id == selectedId).isEmpty
        ? (addresses.isNotEmpty ? addresses.first : null)
        : addresses.firstWhere((a) => a.id == selectedId);

    final discount = checkout.appliedCoupon?.calculateDiscount(subtotal) ?? 0;
    final deliveryFee = checkout.delivery.fee;
    final total = subtotal - discount + deliveryFee;

    final now = DateTime.now();
    final orderNumber =
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
        '${now.millisecondsSinceEpoch.toString().substring(7)}';
    final profile = ref.read(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final order = AppOrder(
      id: now.millisecondsSinceEpoch.toString(),
      userId: uid,
      customerName: profile.name,
      customerEmail: profile.email,
      orderNumber: orderNumber,
      date: now,
      items: cartItems
          .map(
            (c) => OrderItem(
              productId: c.product.id,
              name: c.product.name,
              category: c.product.category,
              variantLabel: c.variantLabel,
              price: c.product.price,
              quantity: c.quantity,
              imageUrl: c.product.images.isNotEmpty
                  ? c.product.images.first
                  : null,
            ),
          )
          .toList(),
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      addressSummary: selectedAddress?.formatted ?? 'No address',
      paymentMethodLabel: checkout.paymentMethod.label,
      status: OrderStatus.pending,
      history: [
        OrderStatusEntry(
          status: OrderStatus.pending,
          timestamp: now,
          note: 'Order placed',
        ),
      ],
    );

    ref.read(ordersProvider.notifier).addOrder(order);
    ref.read(cartProvider.notifier).clear();
    ref.read(checkoutProvider.notifier).reset();

    if (!mounted) return;
    context.pushReplacement(AppRoutes.orderConfirmation, extra: order.id);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final checkout = ref.watch(checkoutProvider);
    final coupons = ref
        .watch(couponsProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <Coupon>[]);
    final addresses = ref.watch(addressProvider);
    final selectedId = ref.watch(selectedAddressIdProvider);
    final selectedAddress = addresses.where((a) => a.id == selectedId).isEmpty
        ? (addresses.isNotEmpty ? addresses.first : null)
        : addresses.firstWhere((a) => a.id == selectedId);

    final discount = checkout.appliedCoupon?.calculateDiscount(subtotal) ?? 0;
    final deliveryFee = checkout.delivery.fee;
    final total = subtotal - discount + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.md),
              children: [
                _SectionCard(
                  title: 'Delivery Address',
                  trailing: TextButton(
                    onPressed: () => context.push('/checkout/address'),
                    child: const Text('Change'),
                  ),
                  child: selectedAddress == null
                      ? Text(
                          'No address selected',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedAddress.fullName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedAddress.phone,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedAddress.formatted,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: AppDimens.md),

                _SectionCard(
                  title: 'Delivery Options',
                  child: RadioGroup<DeliveryOption>(
                    groupValue: checkout.delivery,
                    onChanged: (v) =>
                        ref.read(checkoutProvider.notifier).setDelivery(v!),
                    child: Column(
                      children: DeliveryOption.values.map((opt) {
                        final selected = checkout.delivery == opt;
                        return RadioListTile<DeliveryOption>(
                          value: opt,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            opt.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${opt.eta} · Rs. ${opt.fee.toStringAsFixed(0)}',
                            style: AppTextStyles.caption,
                          ),
                          secondary: selected
                              ? const Icon(
                                  Icons.local_shipping_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                _SectionCard(
                  title: 'Coupon Code',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (checkout.appliedCoupon != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_offer_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${checkout.appliedCoupon!.code} applied — Rs. ${discount.toStringAsFixed(0)} off',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref
                                    .read(checkoutProvider.notifier)
                                    .removeCoupon(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon code',
                                  errorText: _couponError,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: PrimaryButton(
                                label: 'Apply',
                                width: 90,
                                onPressed: () =>
                                    _applyCoupon(subtotal, coupons),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Try WELCOME10 or FLAT500',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                _SectionCard(
                  title: 'Payment Method',
                  child: RadioGroup<PaymentMethod>(
                    groupValue: checkout.paymentMethod,
                    onChanged: (v) => ref
                        .read(checkoutProvider.notifier)
                        .setPaymentMethod(v!),
                    child: Column(
                      children: PaymentMethod.values.map((method) {
                        return RadioListTile<PaymentMethod>(
                          value: method,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            method.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                _SectionCard(
                  title: 'Order Summary',
                  child: Column(
                    children: [
                      _SummaryLine(
                        label: 'Items (${cartItems.length})',
                        value: subtotal,
                      ),
                      if (discount > 0)
                        _SummaryLine(
                          label: 'Coupon Discount',
                          value: -discount,
                          isDiscount: true,
                        ),
                      _SummaryLine(label: 'Delivery Fee', value: deliveryFee),
                      const Divider(height: 20),
                      _SummaryLine(label: 'Total', value: total, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
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
              child: PrimaryButton(
                label: 'Place Order · Rs. ${total.toStringAsFixed(0)}',
                isLoading: _isPlacingOrder,
                onPressed:
                    (selectedAddress == null ||
                        cartItems.isEmpty ||
                        _isPlacingOrder)
                    ? null
                    : _placeOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              ?trailing,
            ],
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
  final bool isDiscount;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary);
    final valueColor = isDiscount
        ? AppColors.success
        : (isBold ? AppColors.primary : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${value < 0 ? '-' : ''}Rs. ${value.abs().toStringAsFixed(0)}',
            style: style.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
