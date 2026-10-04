import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';

/// Author labels used inside `supportTickets/{id}.responses`.
const kCustomerAuthor = 'Customer';
const kStaffAuthor = 'Support Team';

/// Sends chat messages on a support ticket. Messages are appended with
/// `arrayUnion`, so the customer and a support agent writing at the same
/// moment can never overwrite each other (the old admin reply rewrote the
/// whole array, which could silently drop a message).
class SupportChatService {
  final _db = FirebaseFirestore.instance;

  Map<String, dynamic> _message(String author, String text) =>
      TicketResponse(author: author, message: text.trim(), timestamp: DateTime.now()).toMap();

  Future<void> sendCustomerMessage(String ticketId, String text) {
    return _db.collection('supportTickets').doc(ticketId).update({
      'responses': FieldValue.arrayUnion([_message(kCustomerAuthor, text)]),
    });
  }

  Future<void> sendStaffMessage(SupportTicket ticket, String text) {
    return _db.collection('supportTickets').doc(ticket.id).update({
      'responses': FieldValue.arrayUnion([_message(kStaffAuthor, text)]),
      // A first reply moves an "Open" ticket forward automatically.
      if (ticket.status == TicketStatus.open) 'status': TicketStatus.inProgress.name,
    });
  }
}

final supportChatService = SupportChatService();
