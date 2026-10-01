import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/categories/category_model.dart';
import '../../features/home/mock_data.dart';
import '../../features/product/models/product_model.dart';

/// Writes the demo catalog (categories + products, currently defined in
/// mock_data.dart) into Firestore. Run this ONCE from Settings ->
/// Developer -> "Seed Demo Catalog" after setting up a fresh Firebase
/// project — it's idempotent (uses fixed doc IDs matching the mock data's
/// own ids/slugs), so running it again just overwrites the same docs
/// rather than creating duplicates.
class SeedService {
  final _db = FirebaseFirestore.instance;

  Future<void> seedCatalog() async {
    final batch = _db.batch();

    for (final ProductCategory category in mockCategories) {
      final ref = _db.collection('categories').doc(category.id);
      batch.set(ref, category.toFirestoreMap());
    }

    for (final Product product in mockProducts) {
      final ref = _db.collection('products').doc(product.id);
      batch.set(ref, product.toFirestoreMap());
    }

    await batch.commit();
  }
}

final seedService = SeedService();
