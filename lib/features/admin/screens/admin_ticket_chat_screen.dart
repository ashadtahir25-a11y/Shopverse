import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../support/models/ticket_model.dart';
import '../../support/providers/support_chat_service.dart';
import '../../support/widgets/ticket_chat_view.dart';
import '../providers/admin_support_provider.dart';

/// Staff-side chat for one ticket. Watches the live admin ticket stream,
/// so a customer's reply appears instantly without reopening anything.
class AdminTicketChatScreen extends ConsumerWidget {
  final String ticketId;
  const AdminTicketChatScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(adminSupportTicketsProvider).valueOrNull?.where((t) => t.id == ticketId).firstOrNull;

    if (ticket == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
            Text('${ticket.customerName} · ${ticket.customerEmail}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
          ],
        ),
        actions: [
          PopupMenuButton<TicketStatus>(
            tooltip: 'Change status',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (s) => adminSupportService.setStatus(ticket.id, s),
            itemBuilder: (context) => [
              for (final s in TicketStatus.values)
                CheckedPopupMenuItem(value: s, checked: s == ticket.status, child: Text('Mark as ${s.label}')),
            ],
          ),
        ],
      ),
      body: TicketChatView(
        ticket: ticket,
        isStaffView: true,
        onSend: (text) => supportChatService.sendStaffMessage(ticket, text),
      ),
    );
  }
}
