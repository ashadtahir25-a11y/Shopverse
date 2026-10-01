import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import 'banner_model.dart';

final bannersProvider = StreamProvider<List<BannerData>>((ref) {
  if (!FirebaseStatus.isInitialized) {
    return Stream.value(mockBanners);
  }

  return FirebaseFirestore.instance
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return mockBanners;
        final banners =
            snapshot.docs
                .map((doc) => BannerData.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return banners;
      });
});
