enum NotificationType {
  orderPlaced,
  orderShipped,
  orderDelivered,
  orderCancelled,
  returnUpdate,
  promotion,
  priceDrop,
  priceIncrease,
  newProduct,
  wishlistAvailable,
}

extension NotificationTypeX on NotificationType {
  static NotificationType fromWire(String value) =>
      NotificationType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => NotificationType.promotion,
      );
}

/// Lives at `users/{uid}/notifications/{id}` — each customer has their
/// own copy of every notification they've received, so `read` is a
/// perfectly normal per-document field here (unlike a shared top-level
/// collection, there's no risk of one customer's "read" affecting
/// another's).
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? productId;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.productId,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    timestamp: timestamp,
    productId: productId,
    read: read ?? this.read,
  );

  Map<String, dynamic> toFirestoreMap() => {
    'type': type.name,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'productId': productId,
    'read': read,
  };

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: NotificationTypeX.fromWire(data['type'] as String? ?? 'promotion'),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp:
          DateTime.tryParse(data['timestamp'] as String? ?? '') ??
          DateTime.now(),
      productId: data['productId'] as String?,
      read: data['read'] as bool? ?? false,
    );
  }
}
