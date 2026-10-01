import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../checkout/models/coupon_model.dart';

/// Unlike the customer-facing `couponsProvider` (active-only, with a
/// mock-data fallback), this streams EVERY coupon regardless of
/// `isActive` — admins need to see and re-enable expired/paused ones too.
final adminCouponsProvider = StreamProvider.autoDispose<List<Coupon>>((ref) {
  return FirebaseFirestore.instance
      .collection('coupons')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => Coupon.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => b.expiry.compareTo(a.expiry)),
      );
});

/// Admin write operations on coupons. Firestore Rules independently
/// enforce that only admin-role users can actually perform these writes
/// (see firebase/firestore.rules).
class AdminCouponsService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveCoupon(Coupon coupon) async {
    await _db
        .collection('coupons')
        .doc(coupon.code)
        .set(coupon.toFirestoreMap());
  }

  Future<void> deleteCoupon(String code) async {
    await _db.collection('coupons').doc(code).delete();
  }

  Future<void> setActive(Coupon coupon, bool isActive) async {
    await _db.collection('coupons').doc(coupon.code).update({
      'isActive': isActive,
    });
  }

  Future<bool> codeExists(String code) async {
    final doc = await _db.collection('coupons').doc(code).get();
    return doc.exists;
  }
}

final adminCouponsService = AdminCouponsService();
