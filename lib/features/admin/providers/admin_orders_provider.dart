import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/models/order_model.dart';

/// Unlike the customer-facing `ordersProvider` (filtered to the signed-in
/// user's own orders), this streams EVERY order in the store — admins
/// need to see and manage all of them.
final adminOrdersProvider = StreamProvider.autoDispose<List<AppOrder>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => AppOrder.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)),
      );
});

/// Admin write operations on orders. Firestore Rules independently
/// enforce that only admin-role users can actually perform these writes
/// (see firebase/firestore.rules).
class AdminOrdersService {
  final _db = FirebaseFirestore.instance;

  /// Moves an order to [newStatus], appending a history entry — the same
  /// pattern the customer-facing cancel flow uses, so the tracking
  /// timeline (OrderTrackingScreen) works identically regardless of
  /// whether the status change came from the customer or an admin.
  Future<void> updateStatus(
    AppOrder order,
    OrderStatus newStatus, {
    String? note,
  }) async {
    final updatedHistory = [
      ...order.history,
      OrderStatusEntry(
        status: newStatus,
        timestamp: DateTime.now(),
        note: note,
      ),
    ];
    await _db.collection('orders').doc(order.id).update({
      'status': newStatus.name,
      'history': updatedHistory.map((h) => h.toMap()).toList(),
    });
  }
}

final adminOrdersService = AdminOrdersService();
