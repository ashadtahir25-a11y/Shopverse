import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/notification_model.dart';

/// Manages the signed-in customer's own notifications, synced with
/// Firestore (`users/{uid}/notifications/{id}`) — same auth-listening
/// pattern as Cart/Wishlist/Orders. Each customer has their own copy of
/// every notification they've received (written by an admin action —
/// see AdminProductsService.saveProduct's fan-out), so "read" is a
/// normal Firestore field here, kept in sync across devices.
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;
  String? _uid;

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) {
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _notifSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _notifSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
            state = snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
                .toList();
          });
    });
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];

    if (!FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(id)
          .update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final unreadIds = state.where((n) => !n.read).map((n) => n.id).toList();
    state = [for (final n in state) n.copyWith(read: true)];

    if (!FirebaseStatus.isInitialized || _uid == null || unreadIds.isEmpty) {
      return;
    }
    try {
      final batch = FirebaseFirestore.instance.batch();
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications');
      for (final id in unreadIds) {
        batch.update(col.doc(id), {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      (ref) => NotificationsNotifier(),
    );

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
