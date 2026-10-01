import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final String iconKey;
  final List<String> subcategories;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    this.subcategories = const [],
    this.isActive = true,
  });

  /// IconData can't be stored in Firestore, so categories store a string
  /// `iconKey` (e.g. "electronics") which maps to a fixed icon here. Add
  /// new categories' icons to this map as needed — the admin category
  /// form's icon picker reads from this same map, so both stay in sync.
  static const Map<String, IconData> icons = {
    'electronics': Icons.devices_rounded,
    'fashion': Icons.checkroom_rounded,
    'shoes': Icons.sports_baseball_rounded,
    'beauty': Icons.spa_rounded,
    'home': Icons.chair_rounded,
    'accessories': Icons.watch_rounded,
    'toys': Icons.toys_rounded,
    'sports': Icons.sports_basketball_rounded,
    'books': Icons.menu_book_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'other': Icons.category_rounded,
  };

  IconData get icon => icons[iconKey] ?? Icons.category_rounded;

  Map<String, dynamic> toFirestoreMap() => {
    'name': name,
    'iconKey': iconKey,
    'subcategories': subcategories,
    'isActive': isActive,
  };

  factory ProductCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductCategory(
      id: id,
      name: data['name'] as String? ?? '',
      iconKey: data['iconKey'] as String? ?? id,
      subcategories:
          (data['subcategories'] as List?)?.map((e) => e as String).toList() ??
          const [],
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}
