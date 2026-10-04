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

  /// Saves the product, then — if it's genuinely new or its price just
  /// changed — fans a notification out to every customer's own
  /// `users/{uid}/notifications` subcollection (that's how this
  /// project's Firestore Rules model notifications: per-user documents,
  /// `allow create: if isAdmin()`, `allow read/update: if isOwner`).
  /// Written once here by whichever admin made the change, rather than
  /// each customer's device trying to detect the same change itself.
  Future<void> saveProduct(Product product) async {
    final isNew = product.id.isEmpty;
    final id = isNew ? _db.collection('products').doc().id : product.id;

    double? previousPrice;
    if (!isNew) {
      final existing = await _db.collection('products').doc(id).get();
      previousPrice = (existing.data()?['price'] as num?)?.toDouble();
    }

    await _db.collection('products').doc(id).set(product.toFirestoreMap());

    if (isNew) {
      await _broadcastToCustomers(
        type: 'newProduct',
        title: 'New Arrival 🆕',
        message: '${product.name} just landed — check it out.',
        productId: id,
      );
    } else if (previousPrice != null && previousPrice != product.price) {
      final dropped = product.price < previousPrice;
      await _broadcastToCustomers(
        type: dropped ? 'priceDrop' : 'priceIncrease',
        title: dropped ? 'Price Drop 📉' : 'Price Update 📈',
        message: dropped
            ? '${product.name} is now Rs. ${product.price.toStringAsFixed(0)} (was Rs. ${previousPrice.toStringAsFixed(0)}).'
            : '${product.name} is now Rs. ${product.price.toStringAsFixed(0)}.',
        productId: id,
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  Future<void> setPublishStatus(String productId, bool published) async {
    await _db.collection('products').doc(productId).update({
      'status': published ? 'published' : 'draft',
    });
  }

  /// Writes one notification document into every customer's own
  /// `notifications` subcollection. Batched in chunks of 450 (Firestore
  /// caps a single batch at 500 writes) so this stays correct even for
  /// a large customer base, not just small test stores.
  Future<void> _broadcastToCustomers({
    required String type,
    required String title,
    required String message,
    required String productId,
  }) async {
    final customers = await _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .get();
    if (customers.docs.isEmpty) return;

    final timestamp = DateTime.now().toIso8601String();
    const chunkSize = 450;

    for (var i = 0; i < customers.docs.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = customers.docs.skip(i).take(chunkSize);
      for (final customerDoc in chunk) {
        final notifRef = _db
            .collection('users')
            .doc(customerDoc.id)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'type': type,
          'title': title,
          'message': message,
          'timestamp': timestamp,
          'productId': productId,
          'read': false,
        });
      }
      await batch.commit();
    }
  }
}

final adminProductsService = AdminProductsService();
