import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/providers/notification_prefs_provider.dart';
import '../../product/models/product_model.dart';
import 'notification_sender.dart';

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
  /// changed, AND customers can actually see it (status "published") —
  /// fans a notification out to every user's own
  /// `users/{uid}/notifications` subcollection (that's how this
  /// project's Firestore Rules model notifications: per-user documents,
  /// `allow create: if isAdmin()`, `allow read/update: if isOwner`).
  /// Written once here by whichever admin made the change, rather than
  /// each device trying to detect the same change itself.
  Future<void> saveProduct(Product product) async {
    final isNew = product.id.isEmpty;
    final id = isNew ? _db.collection('products').doc().id : product.id;

    double? previousPrice;
    if (!isNew) {
      final existing = await _db.collection('products').doc(id).get();
      previousPrice = (existing.data()?['price'] as num?)?.toDouble();
    }

    await _db.collection('products').doc(id).set(product.toFirestoreMap());

    // A draft/archived product is invisible to shoppers, so announcing it
    // (or its price) would just be noise.
    if (product.status != 'published') return;

    // The product is already saved at this point. A problem while sending
    // notifications must NOT make the admin see "Could not save product",
    // so failures here are logged and swallowed.
    try {
      if (isNew) {
        await _broadcastToAllUsers(
          type: 'newProduct',
          prefKey: kPrefPromotions,
          title: 'New Arrival 🆕',
          message: '${product.name} just landed — check it out.',
          productId: id,
        );
      } else if (previousPrice != null && previousPrice != product.price) {
        final dropped = product.price < previousPrice;
        await _broadcastToAllUsers(
          type: dropped ? 'priceDrop' : 'priceIncrease',
          prefKey: kPrefPriceDrops,
          title: dropped ? 'Price Drop 📉' : 'Price Update 📈',
          message: dropped
              ? '${product.name} is now Rs. ${product.price.toStringAsFixed(0)} (was Rs. ${previousPrice.toStringAsFixed(0)}).'
              : '${product.name} is now Rs. ${product.price.toStringAsFixed(0)}.',
          productId: id,
        );
      }
    } catch (e) {
      debugPrint('Notification broadcast failed: $e');
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

  /// Writes one notification document into every user's own
  /// `notifications` subcollection. Batched in chunks of 450 (Firestore
  /// caps a single batch at 500 writes) so this stays correct even for
  /// a large user base, not just small test stores.
  ///
  /// This deliberately targets ALL users rather than `role == 'customer'`:
  /// the old role filter silently skipped (a) staff accounts — so an
  /// admin testing from their own phone never saw anything — and (b) any
  /// customer whose `role` field was missing or had a stray space/capital
  /// letter. Blocked accounts are skipped (they can't sign in anyway).
  Future<void> _broadcastToAllUsers({
    required String type,
    required String prefKey,
    required String title,
    required String message,
    required String productId,
  }) async {
    final snapshot = await _db.collection('users').get();
    final recipients = snapshot.docs
        // Skip blocked accounts AND anyone who switched this kind of
        // notification off in Settings (see notification_prefs_provider).
        .where((doc) => doc.data()['isBlocked'] != true && wantsNotification(doc.data(), prefKey))
        .toList();
    if (recipients.isEmpty) return;

    final timestamp = DateTime.now().toIso8601String();
    const chunkSize = 450;

    for (var i = 0; i < recipients.length; i += chunkSize) {
      final batch = _db.batch();
      for (final userDoc in recipients.skip(i).take(chunkSize)) {
        final notifRef = _db
            .collection('users')
            .doc(userDoc.id)
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
