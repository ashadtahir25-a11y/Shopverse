import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/ticket_model.dart';

/// Manages the customer's own support tickets, synced with Firestore
/// (`supportTickets/{id}`, filtered by `userId`) — same auth-listening
/// pattern as Orders/Returns. Previously this was in-memory only, so a
/// submitted ticket never actually reached anyone — the Admin Dashboard
/// now has a Support screen that lists and responds to these.
class SupportTicketsNotifier extends StateNotifier<List<SupportTicket>> {
  SupportTicketsNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSub;
  String? _uid;

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) {
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _ticketsSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _ticketsSub = FirebaseFirestore.instance
          .collection('supportTickets')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            final tickets =
                snapshot.docs
                    .map(
                      (doc) => SupportTicket.fromFirestore(doc.id, doc.data()),
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            state = tickets;
          });
    });
  }

  Future<void> submit(SupportTicket ticket) async {
    state = [ticket, ...state];

    if (!FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('supportTickets')
          .doc(ticket.id)
          .set(ticket.toFirestoreMap());
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ticketsSub?.cancel();
    super.dispose();
  }
}

final supportTicketsProvider =
    StateNotifierProvider<SupportTicketsNotifier, List<SupportTicket>>(
      (ref) => SupportTicketsNotifier(),
    );
