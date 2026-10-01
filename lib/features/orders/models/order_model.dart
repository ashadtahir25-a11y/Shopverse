/// AppOrder statuses per PRD Section 20 (Customer order lifecycle).
enum OrderStatus {
  pending,
  confirmed,
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returned,
  refunded,
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.processing => 'Processing',
    OrderStatus.packed => 'Packed',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.outForDelivery => 'Out for Delivery',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.returned => 'Returned',
    OrderStatus.refunded => 'Refunded',
  };

  /// Statuses shown in the visual tracking timeline (PRD §21), in order.
  static const trackingFlow = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  /// Cancellation is only allowed before the order ships (PRD §22).
  bool get isCancellable => [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
  ].contains(this);

  bool get isReturnEligible => this == OrderStatus.delivered;

  String get _wireName => name;

  static OrderStatus fromWire(String value) => OrderStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => OrderStatus.pending,
  );
}

class OrderStatusEntry {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  const OrderStatusEntry({
    required this.status,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'status': status._wireName,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  factory OrderStatusEntry.fromMap(Map<String, dynamic> map) =>
      OrderStatusEntry(
        status: OrderStatusX.fromWire(map['status'] as String),
        timestamp: DateTime.parse(map['timestamp'] as String),
        note: map['note'] as String?,
      );
}

/// A denormalized snapshot of a cart item at the time the order was placed —
/// price/variant must not change retroactively even if the product catalog updates later.
class OrderItem {
  final String productId;
  final String name;
  final String category;
  final String variantLabel;
  final double price;
  final int quantity;
  final bool reviewed;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.variantLabel,
    required this.price,
    required this.quantity,
    this.reviewed = false,
    this.imageUrl,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'category': category,
    'variantLabel': variantLabel,
    'price': price,
    'quantity': quantity,
    'reviewed': reviewed,
    'imageUrl': imageUrl,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    variantLabel: map['variantLabel'] as String? ?? '',
    price: (map['price'] as num).toDouble(),
    quantity: (map['quantity'] as num).toInt(),
    reviewed: map['reviewed'] as bool? ?? false,
    imageUrl: map['imageUrl'] as String?,
  );
}

class AppOrder {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String orderNumber;
  final DateTime date;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String addressSummary;
  final String paymentMethodLabel;
  final OrderStatus status;
  final List<OrderStatusEntry> history;

  const AppOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.orderNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.addressSummary,
    required this.paymentMethodLabel,
    required this.status,
    required this.history,
  });

  AppOrder copyWith({
    OrderStatus? status,
    List<OrderStatusEntry>? history,
    List<OrderItem>? items,
  }) {
    return AppOrder(
      id: id,
      userId: userId,
      customerName: customerName,
      customerEmail: customerEmail,
      orderNumber: orderNumber,
      date: date,
      items: items ?? this.items,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      addressSummary: addressSummary,
      paymentMethodLabel: paymentMethodLabel,
      status: status ?? this.status,
      history: history ?? this.history,
    );
  }

  /// Serializes this order for Firestore. Customer name/email are
  /// denormalized onto the order at checkout time (same reasoning as
  /// OrderItem's product snapshot) so the admin order list can show who
  /// placed each order without an extra Firestore read per row.
  Map<String, dynamic> toFirestoreMap() => {
    'userId': userId,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'orderNumber': orderNumber,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'deliveryFee': deliveryFee,
    'total': total,
    'addressSummary': addressSummary,
    'paymentMethodLabel': paymentMethodLabel,
    'status': status._wireName,
    'history': history.map((h) => h.toMap()).toList(),
  };

  factory AppOrder.fromFirestore(String id, Map<String, dynamic> data) {
    return AppOrder(
      id: id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Unknown',
      customerEmail: data['customerEmail'] as String? ?? '',
      orderNumber: data['orderNumber'] as String? ?? '',
      date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
      items: (data['items'] as List? ?? [])
          .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      addressSummary: data['addressSummary'] as String? ?? '',
      paymentMethodLabel: data['paymentMethodLabel'] as String? ?? '',
      status: OrderStatusX.fromWire(data['status'] as String? ?? 'pending'),
      history: (data['history'] as List? ?? [])
          .map(
            (h) =>
                OrderStatusEntry.fromMap(Map<String, dynamic>.from(h as Map)),
          )
          .toList(),
    );
  }
}
