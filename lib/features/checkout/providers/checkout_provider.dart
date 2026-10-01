import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon_model.dart' as coupon_model;

enum DeliveryOption { standard, express }

extension DeliveryOptionX on DeliveryOption {
  String get label => this == DeliveryOption.standard ? 'Standard Delivery' : 'Express Delivery';
  String get eta => this == DeliveryOption.standard ? '3–5 business days' : '1–2 business days';
  double get fee => this == DeliveryOption.standard ? 250 : 650;
}

enum PaymentMethod { cod, card, wallet, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cod => 'Cash on Delivery',
        PaymentMethod.card => 'Credit / Debit Card',
        PaymentMethod.wallet => 'Mobile Wallet',
        PaymentMethod.bankTransfer => 'Bank Transfer',
      };
}

class CheckoutState {
  final DeliveryOption delivery;
  final PaymentMethod paymentMethod;
  final coupon_model.Coupon? appliedCoupon;

  const CheckoutState({
    this.delivery = DeliveryOption.standard,
    this.paymentMethod = PaymentMethod.cod,
    this.appliedCoupon,
  });

  CheckoutState copyWith({
    DeliveryOption? delivery,
    PaymentMethod? paymentMethod,
    coupon_model.Coupon? appliedCoupon,
    bool clearCoupon = false,
  }) {
    return CheckoutState(
      delivery: delivery ?? this.delivery,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  void setDelivery(DeliveryOption option) => state = state.copyWith(delivery: option);
  void setPaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);
  void applyCoupon(coupon_model.Coupon coupon) => state = state.copyWith(appliedCoupon: coupon);
  void removeCoupon() => state = state.copyWith(clearCoupon: true);
  void reset() => state = const CheckoutState();
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) => CheckoutNotifier());
