import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../../product/models/product_model.dart';

/// Manages wishlist state, synced with Firestore
/// (`users/{uid}/wishlist/{productId}`) whenever Firebase is set up and
/// the user is signed in — see cart_provider.dart for the same pattern
/// and reasoning.
class WishlistNotifier extends StateNotifier<List<Product>> {
  WishlistNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _wishlistSub;
  String? _uid;

  CollectionReference<Map<String, dynamic>>? get _wishlistCollection {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wishlist');
  }

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _wishlistSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _wishlistSub = _wishlistCollection!.snapshots().listen((snapshot) {
        state = snapshot.docs
            .map((doc) => Product.fromFirestore(doc.id, doc.data()))
            .toList();
      });
    });
  }

  bool isWishlisted(String productId) => state.any((p) => p.id == productId);

  void toggle(Product product) {
    final ref = _wishlistCollection;
    if (isWishlisted(product.id)) {
      state = state.where((p) => p.id != product.id).toList();
      ref?.doc(product.id).delete().catchError((_) {});
    } else {
      state = [...state, product];
      ref?.doc(product.id).set(product.toFirestoreMap()).catchError((_) {});
    }
  }

  void remove(String productId) {
    state = state.where((p) => p.id != productId).toList();
    _wishlistCollection?.doc(productId).delete().catchError((_) {});
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _wishlistSub?.cancel();
    super.dispose();
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<Product>>(
  (ref) => WishlistNotifier(),
);
