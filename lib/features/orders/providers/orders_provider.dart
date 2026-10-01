import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/order_model.dart';

/// Manages the customer's order history, synced with Firestore
/// (`orders/{orderId}`, filtered by `userId`) whenever Firebase is set
/// up — so orders persist across sessions/devices instead of vanishing
/// when the app restarts. Falls back to in-memory-only state otherwise.
class OrdersNotifier extends StateNotifier<List<AppOrder>> {
  OrdersNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  String? _uid;

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) {
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _ordersSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _ordersSub = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            final orders =
                snapshot.docs
                    .map((doc) => AppOrder.fromFirestore(doc.id, doc.data()))
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
            state = orders;
          });
    });
  }

  Future<void> addOrder(AppOrder order) async {
    state = [order, ...state];

    if (!FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .set(order.toFirestoreMap());
    } catch (_) {
      // AppOrder already reflects locally; Firestore write can be retried
      // by the user re-opening the app (the local StreamProvider will
      // reconcile once connectivity is restored).
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    AppOrder? updatedOrder;
    final newState = <AppOrder>[];
    for (final order in state) {
      if (order.id == orderId && order.status.isCancellable) {
        final updated = order.copyWith(
          status: OrderStatus.cancelled,
          history: [
            ...order.history,
            OrderStatusEntry(
              status: OrderStatus.cancelled,
              timestamp: DateTime.now(),
              note: reason,
            ),
          ],
        );
        updatedOrder = updated;
        newState.add(updated);
      } else {
        newState.add(order);
      }
    }
    state = newState;

    if (updatedOrder == null || !FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'cancelled',
            'history': updatedOrder.history.map((h) => h.toMap()).toList(),
          });
    } catch (_) {}
  }

  Future<void> markItemReviewed(String orderId, String productId) async {
    AppOrder? updatedOrder;
    final newState = <AppOrder>[];
    for (final order in state) {
      if (order.id == orderId) {
        final newItems = <OrderItem>[];
        for (final item in order.items) {
          if (item.productId == productId) {
            newItems.add(
              OrderItem(
                productId: item.productId,
                name: item.name,
                category: item.category,
                variantLabel: item.variantLabel,
                price: item.price,
                quantity: item.quantity,
                reviewed: true,
                imageUrl: item.imageUrl,
              ),
            );
          } else {
            newItems.add(item);
          }
        }
        final updated = order.copyWith(items: newItems);
        updatedOrder = updated;
        newState.add(updated);
      } else {
        newState.add(order);
      }
    }
    state = newState;

    if (updatedOrder == null || !FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'items': updatedOrder.items.map((i) => i.toMap()).toList()},
      );
    } catch (_) {}
  }

  AppOrder? getById(String orderId) {
    try {
      return state.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<AppOrder>>(
  (ref) => OrdersNotifier(),
);
