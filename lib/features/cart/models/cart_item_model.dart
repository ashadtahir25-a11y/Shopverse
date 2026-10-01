import '../../product/models/product_model.dart';

/// A single line item in the cart. `id` is a composite key of
/// product id + selected variant options, so the same product with
/// different variants (e.g. two colors) becomes two separate cart lines —
/// matching real commercial cart behavior.
class CartItem {
  final String id;
  final Product product;
  final Map<String, String>
  selectedVariants; // { "Color": "Black", "Size": "M" }
  final int quantity;

  const CartItem({
    required this.id,
    required this.product,
    required this.selectedVariants,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;

  String get variantLabel => selectedVariants.isEmpty
      ? ''
      : selectedVariants.entries.map((e) => e.value).join(' / ');

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      product: product,
      selectedVariants: selectedVariants,
      quantity: quantity ?? this.quantity,
    );
  }

  static String buildId(String productId, Map<String, String> variants) {
    final sortedKeys = variants.keys.toList()..sort();
    final variantPart = sortedKeys.map((k) => '$k:${variants[k]}').join('|');
    return '$productId#$variantPart';
  }

  /// Serializes this cart line for Firestore (users/{uid}/cart/{id}).
  Map<String, dynamic> toFirestoreMap() => {
    'productId': product.id,
    'productSnapshot': product.toFirestoreMap(),
    'selectedVariants': selectedVariants,
    'quantity': quantity,
  };

  factory CartItem.fromFirestore(String id, Map<String, dynamic> data) {
    final productId = data['productId'] as String;
    final snapshot = Map<String, dynamic>.from(data['productSnapshot'] as Map);
    return CartItem(
      id: id,
      product: Product.fromFirestore(productId, snapshot),
      selectedVariants: Map<String, String>.from(
        data['selectedVariants'] as Map? ?? {},
      ),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
