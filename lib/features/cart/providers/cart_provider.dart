import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../../product/models/product_model.dart';
import '../models/cart_item_model.dart';

/// Manages the cart's state, kept in sync with Firestore
/// (`users/{uid}/cart/{cartItemId}`) whenever Firebase is set up and the
/// user is signed in — so the cart survives logout/login and switching
/// devices. Falls back to plain in-memory state otherwise (dev mode, see
/// firebase/FIREBASE_SETUP.md), so the app is always usable.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartSub;
  String? _uid;

  CollectionReference<Map<String, dynamic>>? get _cartCollection {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart');
  }

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _cartSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _cartSub = _cartCollection!.snapshots().listen((snapshot) {
        state = snapshot.docs
            .map((doc) => CartItem.fromFirestore(doc.id, doc.data()))
            .toList();
      });
    });
  }

  Future<void> _writeItem(CartItem item) async {
    final ref = _cartCollection;
    if (ref == null) return;
    try {
      await ref.doc(item.id).set(item.toFirestoreMap());
    } catch (_) {
      // Best-effort sync — local state (already updated optimistically
      // below) keeps the UI responsive even if this write fails.
    }
  }

  Future<void> _deleteItem(String id) async {
    final ref = _cartCollection;
    if (ref == null) return;
    try {
      await ref.doc(id).delete();
    } catch (_) {}
  }

  void add(
    Product product,
    Map<String, String> selectedVariants, {
    int quantity = 1,
  }) {
    final id = CartItem.buildId(product.id, selectedVariants);
    final existingIndex = state.indexWhere((item) => item.id == id);

    late CartItem updatedItem;
    if (existingIndex != -1) {
      updatedItem = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + quantity,
      );
      state = [
        for (final item in state)
          if (item.id == id) updatedItem else item,
      ];
    } else {
      updatedItem = CartItem(
        id: id,
        product: product,
        selectedVariants: selectedVariants,
        quantity: quantity,
      );
      state = [...state, updatedItem];
    }
    _writeItem(updatedItem);
  }

  void increment(String cartItemId) {
    CartItem? updated;
    state = [
      for (final item in state)
        if (item.id == cartItemId)
          (updated = item.copyWith(quantity: item.quantity + 1))
        else
          item,
    ];
    if (updated != null) _writeItem(updated);
  }

  void decrement(String cartItemId) {
    CartItem? updated;
    state = [
      for (final item in state)
        if (item.id == cartItemId)
          if (item.quantity > 1)
            (updated = item.copyWith(quantity: item.quantity - 1))
          else
            item
        else
          item,
    ];
    if (updated != null) _writeItem(updated);
  }

  void remove(String cartItemId) {
    state = state.where((item) => item.id != cartItemId).toList();
    _deleteItem(cartItemId);
  }

  void clear() {
    final idsToDelete = state.map((e) => e.id).toList();
    state = [];
    for (final id in idsToDelete) {
      _deleteItem(id);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cartSub?.cancel();
    super.dispose();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

/// Total number of units across all cart lines (used for the bottom-nav badge).
final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (total, item) => total + item.quantity);
});

/// Subtotal before discount/tax/delivery — backend recalculates the
/// authoritative total at checkout time (PRD §66); this is a display value only.
final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (total, item) => total + item.subtotal);
});
