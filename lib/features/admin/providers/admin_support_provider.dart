import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../support/models/ticket_model.dart';

/// Unlike the customer-facing `supportTicketsProvider` (the signed-in
/// user's own tickets), this streams EVERY ticket in the store — support
/// staff need to see and respond to all of them.
final adminSupportTicketsProvider =
    StreamProvider.autoDispose<List<SupportTicket>>((ref) {
      return FirebaseFirestore.instance
          .collection('supportTickets')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => SupportTicket.fromFirestore(doc.id, doc.data()),
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          );
    });

/// Admin actions on support tickets. Firestore Rules independently
/// enforce that only admin-role users can actually perform these writes
/// (see firebase/firestore.rules).
class AdminSupportService {
  final _db = FirebaseFirestore.instance;

  Future<void> reply(SupportTicket ticket, String message) async {
    final updatedResponses = [
      ...ticket.responses,
      TicketResponse(
        author: 'Support Team',
        message: message,
        timestamp: DateTime.now(),
      ),
    ];
    await _db.collection('supportTickets').doc(ticket.id).update({
      'responses': updatedResponses.map((r) => r.toMap()).toList(),
      // Replying moves an "Open" ticket forward automatically.
      if (ticket.status == TicketStatus.open)
        'status': TicketStatus.inProgress.name,
    });
  }

  Future<void> setStatus(String ticketId, TicketStatus status) async {
    await _db.collection('supportTickets').doc(ticketId).update({
      'status': status.name,
    });
  }
}

final adminSupportService = AdminSupportService();
