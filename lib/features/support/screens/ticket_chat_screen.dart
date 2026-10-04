import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/ticket_model.dart';
import '../providers/support_chat_service.dart';
import '../providers/support_provider.dart';
import '../widgets/ticket_chat_view.dart';

/// Customer-side chat with the support team for one ticket. Replies from
/// support show up live (the tickets provider is a Firestore stream), and
/// the customer can answer right here.
class TicketChatScreen extends ConsumerWidget {
  final String ticketId;
  const TicketChatScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(supportTicketsProvider.select((all) {
      for (final t in all) {
        if (t.id == ticketId) return t;
      }
      return null;
    }));

    if (ticket == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Ticket not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
            Text('Support Team · ${ticket.status.label}', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: TicketChatView(
        ticket: ticket,
        isStaffView: false,
        onSend: (text) => supportChatService.sendCustomerMessage(ticket.id, text),
      ),
    );
  }
}
