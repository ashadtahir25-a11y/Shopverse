import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../support/models/ticket_model.dart';
import '../providers/admin_support_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';

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
          final isNarrow = constraints.maxWidth < 700;
          final padding = isNarrow ? AppDimens.md : AppDimens.xl;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support Tickets', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.md),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _statusFilter == null,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ...TicketStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: status.label,
                            selected: _statusFilter == status,
                            onTap: () => setState(() => _statusFilter = status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: ticketsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load tickets',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (tickets) {
                      final filtered = _statusFilter == null
                          ? tickets
                          : tickets
                                .where((t) => t.status == _statusFilter)
                                .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No tickets here',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _TicketRow(
                          ticket: filtered[i],
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) =>
                                _TicketDialog(ticket: filtered[i]),
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
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
                  Expanded(
                    child: Text(
                      ticket.subject,
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
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: AppTextStyles.caption.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${ticket.customerName} · ${ticket.customerEmail}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 6),
              Text(
                ticket.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ticket.id} · ${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}'
                '${ticket.responses.isNotEmpty ? ' · ${ticket.responses.length} repl${ticket.responses.length == 1 ? 'y' : 'ies'}' : ''}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketDialog extends StatefulWidget {
  final SupportTicket ticket;
  const _TicketDialog({required this.ticket});

  @override
  State<_TicketDialog> createState() => _TicketDialogState();
}

class _TicketDialogState extends State<_TicketDialog> {
  final _replyController = TextEditingController();
  late TicketStatus _status = widget.ticket.status;
  bool _isSending = false;

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      await adminSupportService.reply(
        widget.ticket,
        _replyController.text.trim(),
      );
      if (widget.ticket.status != _status) {
        await adminSupportService.setStatus(widget.ticket.id, _status);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send reply. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _saveStatusOnly() async {
    if (_status == widget.ticket.status) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSending = true);
    try {
      await adminSupportService.setStatus(widget.ticket.id, _status);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${_status.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
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
                    Text(
                      '${ticket.customerName} · ${ticket.customerEmail}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    _Bubble(
                      author: ticket.customerName,
                      message: ticket.message,
                      timestamp: ticket.createdAt,
                      isStaff: false,
                    ),
                    ...ticket.responses.map(
                      (r) => _Bubble(
                        author: r.author,
                        message: r.message,
                        timestamp: r.timestamp,
                        isStaff: true,
                      ),
                    ),

                    const SizedBox(height: AppDimens.lg),
                    Text(
                      'Status',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TicketStatus.values.map((status) {
                        final selected = _status == status;
                        return ChoiceChip(
                          label: Text(status.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _status = status),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    Text(
                      'Reply',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _replyController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type your response to the customer...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSending ? null : _saveStatusOnly,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Update Status Only'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Send Reply',
                      isLoading: _isSending,
                      onPressed: _sendReply,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String author;
  final String message;
  final DateTime timestamp;
  final bool isStaff;

  const _Bubble({
    required this.author,
    required this.message,
    required this.timestamp,
    required this.isStaff,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isStaff ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: isStaff ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isStaff ? AppColors.primary : AppColors.textPrimary,
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
