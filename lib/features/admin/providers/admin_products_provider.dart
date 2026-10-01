import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product/models/product_model.dart';

/// Unlike `productsProvider` (customer-facing, published-only, with a
/// mock-data fallback), this streams EVERY product regardless of status
/// — admins need to see and edit drafts too.
final adminProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => Product.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
});

/// Admin write operations on the catalog. Firestore Rules independently
/// enforce that only admin-role users can actually perform these writes
/// (see firebase/firestore.rules) — this class just wraps the calls.
class AdminProductsService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveProduct(Product product) async {
    final id = product.id.isEmpty
        ? _db.collection('products').doc().id
        : product.id;
    await _db.collection('products').doc(id).set(product.toFirestoreMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  Future<void> setPublishStatus(String productId, bool published) async {
    await _db.collection('products').doc(productId).update({
      'status': published ? 'published' : 'draft',
    });
  }
}

final adminProductsService = AdminProductsService();
