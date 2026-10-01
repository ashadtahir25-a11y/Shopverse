import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/category_model.dart';

/// Unlike the customer-facing `categoriesProvider` (active-only, with a
/// mock-data fallback), this streams EVERY category regardless of
/// `isActive` — admins need to see and re-enable hidden ones too.
final adminCategoriesProvider =
    StreamProvider.autoDispose<List<ProductCategory>>((ref) {
      return FirebaseFirestore.instance
          .collection('categories')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) =>
                          ProductCategory.fromFirestore(doc.id, doc.data()),
                    )
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name)),
          );
    });

/// Admin write operations on categories. Firestore Rules independently
/// enforce that only admin-role users can actually perform these writes
/// (see firebase/firestore.rules).
class AdminCategoriesService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveCategory(ProductCategory category) async {
    await _db
        .collection('categories')
        .doc(category.id)
        .set(category.toFirestoreMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('categories').doc(categoryId).delete();
  }

  Future<void> setActive(ProductCategory category, bool isActive) async {
    await _db.collection('categories').doc(category.id).update({
      'isActive': isActive,
    });
  }

  /// True if a document with this id already exists — used to warn when
  /// creating a category whose slug collides with an existing one.
  Future<bool> idExists(String categoryId) async {
    final doc = await _db.collection('categories').doc(categoryId).get();
    return doc.exists;
  }
}

final adminCategoriesService = AdminCategoriesService();
