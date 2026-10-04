import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/ticket_model.dart';
import '../providers/support_chat_service.dart';

class _Msg {
  final String author;
  final String text;
  final DateTime time;
  final bool mine;
  const _Msg(this.author, this.text, this.time, this.mine);
}

/// A live chat thread for one support ticket, used by BOTH sides:
/// the customer ([isStaffView] = false) and support staff (true). The
/// parent passes the freshly-streamed [ticket], so new messages from the
/// other side appear immediately.
class TicketChatView extends StatefulWidget {
  final SupportTicket ticket;
  final bool isStaffView;
  final Future<void> Function(String text) onSend;

  const TicketChatView({super.key, required this.ticket, required this.isStaffView, required this.onSend});

  @override
  State<TicketChatView> createState() => _TicketChatViewState();
}

class _TicketChatViewState extends State<TicketChatView> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _toBottom(animate: false);
  }

  @override
  void didUpdateWidget(covariant TicketChatView old) {
    super.didUpdateWidget(old);
    if (old.ticket.responses.length != widget.ticket.responses.length) _toBottom();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _toBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(end, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  List<_Msg> get _messages {
    final t = widget.ticket;
    final staff = widget.isStaffView;
    return [
      // The ticket's opening message always comes from the customer.
      _Msg(t.customerName, t.message, t.createdAt, !staff),
      for (final r in t.responses)
        _Msg(r.author, r.message, r.timestamp, staff ? r.author != kCustomerAuthor : r.author == kCustomerAuthor),
    ];
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message could not be sent. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(DateTime d) {
    final now = DateTime.now();
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay ? hm : '${d.day}/${d.month}/${d.year}  $hm';
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    final closed = widget.ticket.status == TicketStatus.closed;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(AppDimens.md),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              return Align(
                alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(
                    color: m.mine ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.mine ? 16 : 4),
                      bottomRight: Radius.circular(m.mine ? 4 : 16),
                    ),
                    border: m.mine ? null : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!m.mine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(m.author, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      Text(m.text, style: AppTextStyles.bodyMedium.copyWith(color: m.mine ? Colors.white : AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _time(m.time),
                          style: AppTextStyles.caption.copyWith(fontSize: 10, color: m.mine ? Colors.white70 : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (closed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.md),
            color: AppColors.surface,
            child: Text('This ticket is closed.', textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          )
        else
          Container(
            decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
            padding: const EdgeInsets.fromLTRB(AppDimens.md, 8, 8, 8),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Type a message...', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: (_sending || _input.text.trim().isEmpty) ? null : _send,
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
