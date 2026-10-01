import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reviews/models/review_model.dart';

/// Unlike the customer-facing `reviewsProvider` (approved-only), this
/// streams EVERY review regardless of status — admins need to see
/// pending ones to moderate them.
final adminReviewsProvider = StreamProvider.autoDispose<List<Review>>((ref) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => Review.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)),
      );
});

/// Admin moderation actions. Firestore Rules independently enforce that
/// only admin-role users can actually perform these writes (see
/// firebase/firestore.rules).
class AdminReviewsService {
  final _db = FirebaseFirestore.instance;

  Future<void> setStatus(String reviewId, String status) async {
    await _db.collection('reviews').doc(reviewId).update({'status': status});
  }

  Future<void> delete(String reviewId) async {
    await _db.collection('reviews').doc(reviewId).delete();
  }
}

final adminReviewsService = AdminReviewsService();
