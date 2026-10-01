import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../../home/mock_data.dart' as mock;
import '../models/product_model.dart';

/// Streams all published products from Firestore in real time. Falls back
/// to the local mock catalog (mock_data.dart) when Firebase hasn't been
/// set up yet, or when the Firestore `products` collection is still empty
/// (e.g. before running the one-time seeder — see
/// lib/core/data/seed_service.dart) — this keeps the app fully
/// demonstrable at every stage of setup, never showing a broken blank
/// screen.
final productsProvider = StreamProvider<List<Product>>((ref) {
  if (!FirebaseStatus.isInitialized) {
    return Stream.value(mock.mockProducts);
  }

  return FirebaseFirestore.instance
      .collection('products')
      .where('status', isEqualTo: 'published')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return mock.mockProducts;
        return snapshot.docs
            .map((doc) => Product.fromFirestore(doc.id, doc.data()))
            .toList();
      });
});

final featuredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref
      .watch(productsProvider)
      .whenData((list) => list.where((p) => p.isFeatured).toList());
});

final bestSellerProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref
      .watch(productsProvider)
      .whenData((list) => list.where((p) => p.isBestSeller).toList());
});

final newArrivalProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref
      .watch(productsProvider)
      .whenData((list) => list.where((p) => p.isNewArrival).toList());
});

/// Looks up a single product by id from the already-loaded stream — avoids
/// a second network round-trip since the list is virtually always warm by
/// the time someone taps into a product's details.
final productByIdProvider = Provider.family<AsyncValue<Product?>, String>((
  ref,
  id,
) {
  return ref
      .watch(productsProvider)
      .whenData(
        (list) => list.where((p) => p.id == id).isEmpty
            ? null
            : list.firstWhere((p) => p.id == id),
      );
});
