enum CouponType { percentage, fixed }

class Coupon {
  final String code;
  final CouponType type;
  final double value; // percent (0-100) or fixed Rs amount
  final double minOrder;
  final double? maxDiscount;
  final DateTime expiry;
  final bool active;

  const Coupon({
    required this.code,
    required this.type,
    required this.value,
    required this.minOrder,
    this.maxDiscount,
    required this.expiry,
    this.active = true,
  });

  double calculateDiscount(double subtotal) {
    if (subtotal < minOrder) {
      return 0;
    }
    double discount = type == CouponType.percentage
        ? subtotal * (value / 100)
        : value;
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }
    return discount;
  }

  /// `code` is used as the Firestore document ID (already the coupon's
  /// natural unique key), so it isn't repeated inside the map itself.
  Map<String, dynamic> toFirestoreMap() => {
    'type': type.name,
    'value': value,
    'minOrder': minOrder,
    'maxDiscount': maxDiscount,
    'expiry': expiry.toIso8601String(),
    'isActive': active,
  };

  factory Coupon.fromFirestore(String code, Map<String, dynamic> data) {
    return Coupon(
      code: code,
      type: (data['type'] as String?) == 'fixed'
          ? CouponType.fixed
          : CouponType.percentage,
      value: (data['value'] as num?)?.toDouble() ?? 0,
      minOrder: (data['minOrder'] as num?)?.toDouble() ?? 0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble(),
      expiry:
          DateTime.tryParse(data['expiry'] as String? ?? '') ?? DateTime.now(),
      active: data['isActive'] as bool? ?? true,
    );
  }
}

final List<Coupon> mockCoupons = [
  Coupon(
    code: 'WELCOME10',
    type: CouponType.percentage,
    value: 10,
    minOrder: 2000,
    maxDiscount: 1500,
    expiry: DateTime(2027, 1, 1),
  ),
  Coupon(
    code: 'FLAT500',
    type: CouponType.fixed,
    value: 500,
    minOrder: 5000,
    expiry: DateTime(2027, 1, 1),
  ),
];

/// Returns (coupon, errorMessage). If errorMessage is non-null, the coupon
/// could not be applied and the message should be shown to the user.
/// [availableCoupons] comes from Firestore in the real app (see
/// coupon_provider.dart) — this stays a pure function so it's easy to
/// test and doesn't need to know where the list came from.
/// NOTE: this is client-side validation for UI/UX purposes only — the
/// backend must always re-validate and be the source of truth (PRD §16, §66).
(Coupon?, String?) validateCoupon(
  String code,
  double subtotal,
  List<Coupon> availableCoupons,
) {
  final normalized = code.trim().toUpperCase();
  if (normalized.isEmpty) {
    return (null, 'Enter a coupon code');
  }

  Coupon? coupon;
  for (final c in availableCoupons) {
    if (c.code == normalized) {
      coupon = c;
      break;
    }
  }

  if (coupon == null) {
    return (null, 'Invalid coupon code');
  }
  if (!coupon.active) {
    return (null, 'This coupon is no longer active');
  }
  if (DateTime.now().isAfter(coupon.expiry)) {
    return (null, 'This coupon has expired');
  }
  if (subtotal < coupon.minOrder) {
    return (
      null,
      'Minimum order of Rs. ${coupon.minOrder.toStringAsFixed(0)} required',
    );
  }

  return (coupon, null);
}
