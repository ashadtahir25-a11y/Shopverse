import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/widgets/banner_model.dart';

/// Unlike the customer-facing `bannersProvider` (active-only, with a
/// mock-data fallback), this streams EVERY banner regardless of
/// `isActive` — admins need to see and re-enable paused ones too.
final adminBannersProvider = StreamProvider.autoDispose<List<BannerData>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('banners')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => BannerData.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
});

/// Admin write operations on banners. Firestore Rules independently
/// enforce that only admin-role users can actually perform these writes
/// (see firebase/firestore.rules).
class AdminBannersService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveBanner(BannerData banner) async {
    final id = banner.id.isEmpty
        ? _db.collection('banners').doc().id
        : banner.id;
    await _db.collection('banners').doc(id).set(banner.toFirestoreMap());
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }

  Future<void> setActive(BannerData banner, bool isActive) async {
    await _db.collection('banners').doc(banner.id).update({
      'isActive': isActive,
    });
  }
}

final adminBannersService = AdminBannersService();
