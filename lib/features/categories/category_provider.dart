import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/firebase_config.dart';
import '../home/mock_data.dart' as mock;
import 'category_model.dart';

/// Streams all active categories from Firestore in real time, falling
/// back to the local mock catalog when Firebase isn't set up yet or the
/// `categories` collection is still empty — see productsProvider for the
/// same reasoning (never show a broken blank screen mid-setup).
final categoriesProvider = StreamProvider<List<ProductCategory>>((ref) {
  if (!FirebaseStatus.isInitialized) {
    return Stream.value(mock.mockCategories);
  }

  return FirebaseFirestore.instance
      .collection('categories')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return mock.mockCategories;
        return snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc.id, doc.data()))
            .toList();
      });
});
