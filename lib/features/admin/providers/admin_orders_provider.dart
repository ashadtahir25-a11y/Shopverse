import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/providers/notification_prefs_provider.dart';
import '../../orders/models/order_model.dart';
import 'notification_sender.dart';

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

    // The status is already saved. A failure to notify must never make
    // the admin think the update itself failed.
    try {
      await _notifyCustomer(order, newStatus);
    } catch (e) {
      debugPrint('Order notification failed: $e');
    }
  }

  /// Tells the customer their order moved on — only if they kept "Order
  /// Updates" switched on in Settings.
  Future<void> _notifyCustomer(AppOrder order, OrderStatus status) async {
    final no = order.orderNumber;
    final (String? type, String title, String message) = switch (status) {
      OrderStatus.pending => (null, '', ''),
      OrderStatus.confirmed => ('orderPlaced', 'Order Confirmed ✅', 'Your order $no has been confirmed.'),
      OrderStatus.processing => ('orderPlaced', 'Order Being Prepared 🛠️', 'We are preparing your order $no.'),
      OrderStatus.packed => ('orderPlaced', 'Order Packed 📦', 'Your order $no is packed and ready to ship.'),
      OrderStatus.shipped => ('orderShipped', 'Order Shipped 🚚', 'Your order $no is on its way.'),
      OrderStatus.outForDelivery => ('orderShipped', 'Out for Delivery 🛵', 'Your order $no is out for delivery today.'),
      OrderStatus.delivered => ('orderDelivered', 'Order Delivered 🎉', 'Your order $no has been delivered. Enjoy!'),
      OrderStatus.cancelled => ('orderCancelled', 'Order Cancelled ❌', 'Your order $no has been cancelled.'),
      OrderStatus.returned => ('returnUpdate', 'Order Returned', 'Your order $no is marked as returned.'),
      OrderStatus.refunded => ('returnUpdate', 'Refund Processed 💸', 'A refund for your order $no has been processed.'),
    };
    if (type == null) return;
    await notifyUser(uid: order.userId, prefKey: kPrefOrderUpdates, type: type, title: title, message: message);
  }
}

final adminOrdersService = AdminOrdersService();
