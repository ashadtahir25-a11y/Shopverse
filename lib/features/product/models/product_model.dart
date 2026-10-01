/// A single selectable variant option, e.g. Color: "Black" or Storage: "128GB".
class VariantOption {
  final String id;
  final String label;
  final String? colorHex; // used when the attribute type is "color"

  const VariantOption({required this.id, required this.label, this.colorHex});

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'colorHex': colorHex,
  };

  factory VariantOption.fromMap(Map<String, dynamic> map) => VariantOption(
    id: map['id'] as String,
    label: map['label'] as String,
    colorHex: map['colorHex'] as String?,
  );
}

/// A variant attribute group, e.g. "Color" -> [Black, Blue, White].
class VariantAttribute {
  final String name; // "Color", "Storage", "Size"
  final List<VariantOption> options;

  const VariantAttribute({required this.name, required this.options});

  Map<String, dynamic> toMap() => {
    'name': name,
    'options': options.map((o) => o.toMap()).toList(),
  };

  factory VariantAttribute.fromMap(Map<String, dynamic> map) =>
      VariantAttribute(
        name: map['name'] as String,
        options: (map['options'] as List)
            .map(
              (o) => VariantOption.fromMap(Map<String, dynamic>.from(o as Map)),
            )
            .toList(),
      );
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final String category;
  final List<String> images;
  final double price;
  final double? originalPrice; // null if no discount
  final double rating;
  final int reviewCount;
  final int stock;
  final String description;
  final List<VariantAttribute> variants;
  final bool isFeatured;
  final bool isBestSeller;
  final bool isNewArrival;
  final String status; // 'draft' | 'published' | 'archived'

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.sku,
    required this.category,
    required this.images,
    required this.price,
    this.originalPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.stock = 10,
    this.description = '',
    this.variants = const [],
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isNewArrival = false,
    this.status = 'published',
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  bool get inStock => stock > 0;

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? sku,
    String? category,
    List<String>? images,
    double? price,
    double? originalPrice,
    bool clearOriginalPrice = false,
    double? rating,
    int? reviewCount,
    int? stock,
    String? description,
    List<VariantAttribute>? variants,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNewArrival,
    String? status,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      images: images ?? this.images,
      price: price ?? this.price,
      originalPrice: clearOriginalPrice
          ? null
          : (originalPrice ?? this.originalPrice),
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      variants: variants ?? this.variants,
      isFeatured: isFeatured ?? this.isFeatured,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      status: status ?? this.status,
    );
  }

  /// Converts this product into a Firestore-writable map. Used by the
  /// one-time demo-catalog seeder (see lib/core/data/seed_service.dart)
  /// and by the Admin Dashboard's product editor.
  Map<String, dynamic> toFirestoreMap() => {
    'name': name,
    'brand': brand,
    'sku': sku,
    'category': category,
    'images': images,
    'price': price,
    'originalPrice': originalPrice,
    'rating': rating,
    'reviewCount': reviewCount,
    'stock': stock,
    'description': description,
    'variants': variants.map((v) => v.toMap()).toList(),
    'isFeatured': isFeatured,
    'isBestSeller': isBestSeller,
    'isNewArrival': isNewArrival,
    'status': status,
  };

  /// Builds a [Product] from a Firestore document snapshot's data + id.
  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      sku: data['sku'] as String? ?? '',
      category: data['category'] as String? ?? '',
      images:
          (data['images'] as List?)?.map((e) => e as String).toList() ??
          const [],
      price: (data['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      variants:
          (data['variants'] as List?)
              ?.map(
                (v) => VariantAttribute.fromMap(
                  Map<String, dynamic>.from(v as Map),
                ),
              )
              .toList() ??
          const [],
      isFeatured: data['isFeatured'] as bool? ?? false,
      isBestSeller: data['isBestSeller'] as bool? ?? false,
      isNewArrival: data['isNewArrival'] as bool? ?? false,
      status: data['status'] as String? ?? 'published',
    );
  }
}
