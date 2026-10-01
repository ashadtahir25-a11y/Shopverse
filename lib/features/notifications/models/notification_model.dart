enum NotificationType {
  orderPlaced,
  orderShipped,
  orderDelivered,
  orderCancelled,
  returnUpdate,
  promotion,
  priceDrop,
  wishlistAvailable,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        timestamp: timestamp,
        read: read ?? this.read,
      );
}
