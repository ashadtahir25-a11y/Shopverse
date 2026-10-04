import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/full_image_viewer.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../returns/models/return_model.dart';
import '../providers/admin_returns_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';

class AdminReturnsScreen extends StatelessWidget {
  const AdminReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      section: 'Returns',
      child: const AdminShell(activeLabel: 'Returns', child: _ReturnsContent()),
    );
  }
}

class _ReturnsContent extends ConsumerStatefulWidget {
  const _ReturnsContent();

  @override
  ConsumerState<_ReturnsContent> createState() => _ReturnsContentState();
}

class _ReturnsContentState extends ConsumerState<_ReturnsContent> {
  ReturnStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(adminReturnsProvider);

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
                Text('Returns', style: AppTextStyles.h2),
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
                      ...ReturnStatus.values.map(
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
                  child: returnsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load returns',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (returns) {
                      final filtered = _statusFilter == null
                          ? returns
                          : returns
                                .where((r) => r.status == _statusFilter)
                                .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No return requests here',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ReturnRow(
                          request: filtered[i],
                          onTap: () => _showStatusDialog(context, filtered[i]),
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

  void _showStatusDialog(BuildContext context, ReturnRequest request) {
    showDialog(
      context: context,
      builder: (context) => _ReturnStatusDialog(request: request),
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

class _ReturnRow extends StatelessWidget {
  final ReturnRequest request;
  final VoidCallback onTap;
  const _ReturnRow({required this.request, required this.onTap});

  Color get _statusColor => switch (request.status) {
    ReturnStatus.refunded => AppColors.success,
    ReturnStatus.rejected => AppColors.error,
    ReturnStatus.requested || ReturnStatus.underReview => AppColors.warning,
    _ => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(request.customerName, style: AppTextStyles.caption),
                    Text(request.reason, style: AppTextStyles.caption),
                  ],
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
                  request.status.label,
                  style: AppTextStyles.caption.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnStatusDialog extends StatefulWidget {
  final ReturnRequest request;
  const _ReturnStatusDialog({required this.request});

  @override
  State<_ReturnStatusDialog> createState() => _ReturnStatusDialogState();
}

class _ReturnStatusDialogState extends State<_ReturnStatusDialog> {
  late ReturnStatus _selected = widget.request.status;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_selected == widget.request.status) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await adminReturnsService.setStatus(widget.request.id, _selected);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Updated to ${_selected.label}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(request.productName, style: AppTextStyles.h4),
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
                    _InfoRow(label: 'Customer', value: request.customerName),
                    _InfoRow(label: 'Order ID', value: request.orderId),
                    _InfoRow(label: 'Quantity', value: '${request.quantity}'),
                    _InfoRow(label: 'Reason', value: request.reason),
                    if (request.description.isNotEmpty)
                      _InfoRow(label: 'Details', value: request.description),
                    _InfoRow(
                      label: 'Requested',
                      value:
                          '${request.requestedAt.day}/${request.requestedAt.month}/${request.requestedAt.year}',
                    ),
                    if (request.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: request.imageUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => showFullImageViewer(
                              context,
                              request.imageUrls[i],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusSm,
                              ),
                              child: Image.network(
                                request.imageUrls[i],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.lg),

                    Text(
                      'Update Status',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ReturnStatus.values.map((status) {
                        final selected = _selected == status;
                        return ChoiceChip(
                          label: Text(status.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _selected = status),
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
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: PrimaryButton(
                label: 'Save',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
