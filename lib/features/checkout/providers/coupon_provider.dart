import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/coupon_model.dart';

/// Streams active coupons from Firestore in real time, falling back to
/// the local mock coupons when Firebase isn't set up yet or the
/// `coupons` collection is still empty — same reasoning as
/// productsProvider/categoriesProvider (never show a broken checkout
/// mid-setup, and "Try WELCOME10 or FLAT500" in the checkout hint text
/// keeps working out of the box).
final couponsProvider = StreamProvider<List<Coupon>>((ref) {
  if (!FirebaseStatus.isInitialized) {
    return Stream.value(mockCoupons);
  }

  return FirebaseFirestore.instance
      .collection('coupons')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return mockCoupons;
        return snapshot.docs
            .map((doc) => Coupon.fromFirestore(doc.id, doc.data()))
            .toList();
      });
});
