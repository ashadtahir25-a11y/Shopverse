import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../returns/models/return_model.dart';

/// Unlike the customer-facing `returnsProvider` (the signed-in user's own
/// requests), this streams EVERY return request in the store — admins
/// need to process all of them.
final adminReturnsProvider = StreamProvider.autoDispose<List<ReturnRequest>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('returns')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => ReturnRequest.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt)),
      );
});

/// Admin write operations on return requests. Firestore Rules
/// independently enforce that only admin-role users can actually perform
/// these writes (see firebase/firestore.rules).
class AdminReturnsService {
  final _db = FirebaseFirestore.instance;

  Future<void> setStatus(String returnId, ReturnStatus status) async {
    await _db.collection('returns').doc(returnId).update({
      'status': status.name,
    });
  }
}

final adminReturnsService = AdminReturnsService();
