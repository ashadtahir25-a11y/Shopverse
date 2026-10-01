import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/return_model.dart';

/// Manages the customer's own return/refund requests, synced with
/// Firestore (`returns/{id}`, filtered by `userId`) — same auth-listening
/// pattern as OrdersNotifier.
class ReturnsNotifier extends StateNotifier<List<ReturnRequest>> {
  ReturnsNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _returnsSub;
  String? _uid;

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) {
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _returnsSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _returnsSub = FirebaseFirestore.instance
          .collection('returns')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            final requests =
                snapshot.docs
                    .map(
                      (doc) => ReturnRequest.fromFirestore(doc.id, doc.data()),
                    )
                    .toList()
                  ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
            state = requests;
          });
    });
  }

  Future<void> submit(ReturnRequest request) async {
    state = [request, ...state];

    if (!FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('returns')
          .doc(request.id)
          .set(request.toFirestoreMap());
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _returnsSub?.cancel();
    super.dispose();
  }
}

final returnsProvider =
    StateNotifierProvider<ReturnsNotifier, List<ReturnRequest>>(
      (ref) => ReturnsNotifier(),
    );
