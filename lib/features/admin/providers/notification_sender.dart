import 'package:cloud_firestore/cloud_firestore.dart';

/// Does this user want notifications of the kind [prefKey]?
/// `prefKey` is one of the kPref... keys (orderUpdates / promotions /
/// priceDrops). A user who never touched Settings has no stored choice,
/// which counts as "yes".
bool wantsNotification(Map<String, dynamic>? userData, String prefKey) {
  final prefs = userData?['notificationPrefs'];
  if (prefs is Map) return prefs[prefKey] != false;
  return true;
}

/// Sends one notification to one user, but only if that user has the
/// matching switch on in Settings. Used for things aimed at a single
/// customer (e.g. their order's status changed).
Future<void> notifyUser({
  required String uid,
  required String prefKey,
  required String type,
  required String title,
  required String message,
}) async {
  if (uid.isEmpty) return;
  final db = FirebaseFirestore.instance;
  final user = await db.collection('users').doc(uid).get();
  final data = user.data();
  if (data?['isBlocked'] == true || !wantsNotification(data, prefKey)) return;

  await db.collection('users').doc(uid).collection('notifications').add({
    'type': type,
    'title': title,
    'message': message,
    'timestamp': DateTime.now().toIso8601String(),
    'productId': null,
    'read': false,
  });
}
