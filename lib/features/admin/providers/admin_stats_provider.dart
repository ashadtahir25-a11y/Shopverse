import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live counts for the Admin Dashboard's summary cards (PRD §28).
///
/// PERFORMANCE NOTE: these use `.autoDispose` — without it, the first
/// time any admin opened the Dashboard, these 7 full-collection listeners
/// (products, orders x3 queries, users, returns) would stay open and
/// keep downloading updates for the rest of the app session, even for
/// ordinary customers using the app afterward, since these providers
/// aren't scoped to the Dashboard screen being visible. `.autoDispose`
/// cancels each underlying Firestore listener once nothing is watching
/// it (i.e. once the admin navigates away from the Dashboard).
///
/// Uses simple snapshot listeners for now — fine at this scale; if the
/// catalog/order volume grows large, swap these for Firestore's
/// server-side `.count()` aggregation queries to avoid downloading full
/// document lists just to count them.
final totalProductsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map((s) => s.docs.length);
});

final totalOrdersCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .snapshots()
      .map((s) => s.docs.length);
});

final pendingOrdersCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.length);
});

final totalCustomersCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'customer')
      .snapshots()
      .map((s) => s.docs.length);
});

final lowStockProductsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .where('stock', isLessThanOrEqualTo: 5)
      .snapshots()
      .map((s) => s.docs.length);
});

final pendingReturnsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('returns')
      .where('status', isEqualTo: 'requested')
      .snapshots()
      .map((s) => s.docs.length);
});

/// Total revenue across all orders (simple sum, not time-windowed —
/// a proper "sales by day/week/month" chart is a good next increment).
final totalRevenueProvider = StreamProvider.autoDispose<double>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .snapshots()
      .map(
        (s) => s.docs.fold<double>(
          0,
          (runningTotal, doc) =>
              runningTotal + ((doc.data()['total'] as num?)?.toDouble() ?? 0),
        ),
      );
});
