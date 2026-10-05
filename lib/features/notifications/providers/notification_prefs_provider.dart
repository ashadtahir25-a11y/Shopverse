import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';

/// Keys of the three switches under Settings -> Notification Preferences.
/// They are stored on each user's own document (`users/{uid}`, field
/// `notificationPrefs`), so every account has its own settings and they
/// follow the account across devices.
///
/// The mapping to notification types:
///   orderUpdates -> order status / delivery notifications
///   promotions   -> new arrivals, sales
///   priceDrops   -> product price changes
const kPrefOrderUpdates = 'orderUpdates';
const kPrefPromotions = 'promotions';
const kPrefPriceDrops = 'priceDrops';

class NotificationPrefs {
  final bool orderUpdates;
  final bool promotions;
  final bool priceDrops;

  /// Everything is ON until the user switches it off, so notifications
  /// keep working for accounts that never opened Settings.
  const NotificationPrefs({this.orderUpdates = true, this.promotions = true, this.priceDrops = true});

  factory NotificationPrefs.fromMap(Object? raw) {
    if (raw is! Map) return const NotificationPrefs();
    return NotificationPrefs(
      orderUpdates: raw[kPrefOrderUpdates] != false,
      promotions: raw[kPrefPromotions] != false,
      priceDrops: raw[kPrefPriceDrops] != false,
    );
  }

  NotificationPrefs withValue(String key, bool value) => NotificationPrefs(
        orderUpdates: key == kPrefOrderUpdates ? value : orderUpdates,
        promotions: key == kPrefPromotions ? value : promotions,
        priceDrops: key == kPrefPriceDrops ? value : priceDrops,
      );
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs()) {
    _listen();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  String? _uid;

  void _listen() {
    if (!FirebaseStatus.isInitialized) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _docSub?.cancel();
      _uid = user?.uid;
      if (user == null) {
        state = const NotificationPrefs();
        return;
      }
      _docSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        state = NotificationPrefs.fromMap(doc.data()?['notificationPrefs']);
      });
    });
  }

  /// Flips one switch. The screen updates instantly; if saving fails the
  /// switch goes back to its real value.
  Future<void> set(String key, bool value) async {
    final previous = state;
    state = state.withValue(key, value);
    final uid = _uid;
    if (uid == null || !FirebaseStatus.isInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'notificationPrefs.$key': value});
    } catch (_) {
      state = previous;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>((ref) => NotificationPrefsNotifier());
