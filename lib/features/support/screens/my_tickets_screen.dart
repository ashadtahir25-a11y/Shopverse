import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/ticket_model.dart';
import '../providers/support_chat_service.dart';
import '../providers/support_provider.dart';
import 'ticket_chat_screen.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  Color _statusColor(TicketStatus status) => switch (status) {
        TicketStatus.open => AppColors.warning,
        TicketStatus.inProgress => AppColors.info,
        TicketStatus.resolved => AppColors.success,
        TicketStatus.closed => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Tickets')),
      body: tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No support tickets yet', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('Your submitted tickets will appear here', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppDimens.lg),
                  TextButton(onPressed: () => context.push('/help-support/contact'), child: const Text('Open a New Ticket')),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimens.md),
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = tickets[i];
                final color = _statusColor(t.status);
                // Preview shows the latest message in the conversation.
                final last = t.responses.isNotEmpty ? t.responses.last : null;
                final preview = last == null
                    ? t.message
                    : '${last.author == kCustomerAuthor ? 'You' : 'Support'}: ${last.message}';
                final waitingOnYou = last != null && last.author != kCustomerAuthor && t.status != TicketStatus.closed;

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TicketChatScreen(ticketId: t.id))),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: waitingOnYou ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(t.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text(t.status.label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text('${t.id} · ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}', style: AppTextStyles.caption)),
                            if (waitingOnYou)
                              Text('New reply', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/help-support/contact'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Ticket', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
