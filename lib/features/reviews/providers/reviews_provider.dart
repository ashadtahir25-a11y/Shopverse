import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/review_model.dart';

/// Streams every APPROVED review in real time — new reviews start as
/// `status: 'pending'` and only appear here once an admin approves them
/// (see the Admin Dashboard's Reviews screen). Product Details filters
/// this list client-side by productId, same pattern used throughout the
/// app for small collections.
final reviewsProvider = StreamProvider<List<Review>>((ref) {
  if (!FirebaseStatus.isInitialized) {
    return Stream.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('reviews')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc.id, doc.data()))
            .toList(),
      );
});

class ReviewsService {
  final _db = FirebaseFirestore.instance;

  Future<void> submit(Review review) async {
    await _db.collection('reviews').doc(review.id).set(review.toFirestoreMap());
  }
}

final reviewsService = ReviewsService();
