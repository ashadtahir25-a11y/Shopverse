import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final List<AppNotification> _seedNotifications = [
  AppNotification(
    id: 'n1',
    type: NotificationType.promotion,
    title: 'Season Sale is Live! 🎉',
    message: 'Up to 40% off on electronics. Limited time only.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'n2',
    type: NotificationType.priceDrop,
    title: 'Price Drop Alert',
    message: 'AeroFit Wireless Headphones just dropped by 15%.',
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
  ),
  AppNotification(
    id: 'n3',
    type: NotificationType.wishlistAvailable,
    title: 'Back in Stock',
    message: 'An item in your wishlist is available again.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    read: true,
  ),
];

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(_seedNotifications);

  void add(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [for (final n in state) if (n.id == id) n.copyWith(read: true) else n];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(read: true)];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
