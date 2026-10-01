import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/ticket_model.dart';
import '../providers/support_provider.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  Color _statusColor(TicketStatus status) => switch (status) {
    TicketStatus.open => AppColors.warning,
    TicketStatus.inProgress => AppColors.info,
    TicketStatus.resolved => AppColors.success,
    TicketStatus.closed => AppColors.textMuted,
  };

  void _showTicketDetail(BuildContext context, SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(ticket.subject, style: AppTextStyles.h4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MessageBubble(
                        author: 'You',
                        message: ticket.message,
                        timestamp: ticket.createdAt,
                        isMe: true,
                      ),
                      ...ticket.responses.map(
                        (r) => _MessageBubble(
                          author: r.author,
                          message: r.message,
                          timestamp: r.timestamp,
                          isMe: false,
                        ),
                      ),
                      if (ticket.responses.isEmpty) ...[
                        const SizedBox(height: AppDimens.md),
                        Text(
                          'No replies yet — our team will respond soon.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text('No support tickets yet', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(
                    'Your submitted tickets will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  TextButton(
                    onPressed: () => context.push('/help-support/contact'),
                    child: const Text('Open a New Ticket'),
                  ),
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
                return GestureDetector(
                  onTap: () => _showTicketDetail(context, t),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                t.subject,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t.status.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${t.id} · ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
                                style: AppTextStyles.caption,
                              ),
                            ),
                            if (t.responses.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${t.responses.length} repl${t.responses.length == 1 ? 'y' : 'ies'}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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

class _MessageBubble extends StatelessWidget {
  final String author;
  final String message;
  final DateTime timestamp;
  final bool isMe;

  const _MessageBubble({
    required this.author,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: isMe ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isMe ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(message, style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(
                '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
