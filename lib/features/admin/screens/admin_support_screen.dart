import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../support/models/ticket_model.dart';
import '../../support/providers/support_chat_service.dart';
import '../providers/admin_support_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import 'admin_ticket_chat_screen.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      section: 'Support',
      child: const AdminShell(activeLabel: 'Support', child: _SupportContent()),
    );
  }
}

class _SupportContent extends ConsumerStatefulWidget {
  const _SupportContent();

  @override
  ConsumerState<_SupportContent> createState() => _SupportContentState();
}

class _SupportContentState extends ConsumerState<_SupportContent> {
  TicketStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 700 ? AppDimens.md : AppDimens.xl;
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support Chats', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.md),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(label: 'All', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                      for (final s in TicketStatus.values)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(label: s.label, selected: _statusFilter == s, onTap: () => setState(() => _statusFilter = s)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: ticketsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Couldn\u2019t load tickets', style: AppTextStyles.bodyMedium)),
                    data: (tickets) {
                      final filtered = _statusFilter == null ? tickets : tickets.where((t) => t.status == _statusFilter).toList();
                      if (filtered.isEmpty) {
                        return Center(child: Text('No tickets here', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)));
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _TicketRow(
                          ticket: filtered[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AdminTicketChatScreen(ticketId: filtered[i].id)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  const _TicketRow({required this.ticket, required this.onTap});

  Color get _statusColor => switch (ticket.status) {
        TicketStatus.open => AppColors.warning,
        TicketStatus.inProgress => AppColors.info,
        TicketStatus.resolved => AppColors.success,
        TicketStatus.closed => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final last = ticket.responses.isNotEmpty ? ticket.responses.last : null;
    // The customer spoke last (or nobody has replied yet) -> staff's turn.
    final needsReply = ticket.status != TicketStatus.closed && (last == null || last.author == kCustomerAuthor);
    final preview = last == null ? ticket.message : '${last.author == kCustomerAuthor ? ticket.customerName : 'You'}: ${last.message}';

    return SurfaceCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (needsReply)
                    Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  Expanded(child: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(ticket.status.label, style: AppTextStyles.caption.copyWith(color: _statusColor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${ticket.customerName} · ${ticket.customerEmail}', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(
                '${ticket.id} · ${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}'
                '${needsReply ? ' · Awaiting your reply' : ''}',
                style: AppTextStyles.caption.copyWith(color: needsReply ? AppColors.accent : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
