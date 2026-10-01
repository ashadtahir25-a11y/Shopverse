import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/admin_customers_provider.dart';

Future<void> showCustomerDetailDialog(
  BuildContext context,
  AdminCustomer customer,
) {
  return showDialog(
    context: context,
    builder: (context) => _CustomerDetailDialog(customer: customer),
  );
}

String _roleLabel(String role) => switch (role) {
  'admin' => 'Admin',
  'manager' => 'Manager',
  'order_manager' => 'Order Manager',
  'product_manager' => 'Product Manager',
  'support_staff' => 'Support Staff',
  _ => 'Customer',
};

class _CustomerDetailDialog extends StatefulWidget {
  final AdminCustomer customer;
  const _CustomerDetailDialog({required this.customer});

  @override
  State<_CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<_CustomerDetailDialog> {
  late String _selectedRole = widget.customer.role;
  bool _isSaving = false;

  bool get _isSelf =>
      FirebaseAuth.instance.currentUser?.uid == widget.customer.uid;

  Future<void> _saveRole() async {
    setState(() => _isSaving = true);
    try {
      await adminCustomersService.setRole(widget.customer.uid, _selectedRole);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.customer.name} is now ${_roleLabel(_selectedRole)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update role. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleBlocked() async {
    final newValue = !widget.customer.isBlocked;
    try {
      await adminCustomersService.setBlocked(widget.customer.uid, newValue);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? '${widget.customer.name} blocked'
                : '${widget.customer.name} unblocked',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update account. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Customer Details', style: AppTextStyles.h4),
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
                    Center(
                      child: Column(
                        children: [
                          UserAvatar(
                            avatarUrl: customer.avatarUrl,
                            name: customer.name,
                            size: 72,
                          ),
                          const SizedBox(height: 10),
                          Text(customer.name, style: AppTextStyles.h4),
                          Text(
                            customer.email,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_isSelf) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'This is you',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    _InfoRow(
                      label: 'Phone',
                      value: customer.phone.isEmpty ? '—' : customer.phone,
                    ),
                    _InfoRow(
                      label: 'Joined',
                      value: customer.createdAt != null
                          ? '${customer.createdAt!.day}/${customer.createdAt!.month}/${customer.createdAt!.year}'
                          : '—',
                    ),
                    _InfoRow(
                      label: 'Account Status',
                      value: customer.isBlocked ? 'Blocked' : 'Active',
                    ),
                    const SizedBox(height: AppDimens.lg),

                    Text(
                      'Role',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kAvailableRoles.map((role) {
                        final selected = _selectedRole == role;
                        return ChoiceChip(
                          label: Text(_roleLabel(role)),
                          selected: selected,
                          onSelected: _isSelf
                              ? null
                              : (_) => setState(() => _selectedRole = role),
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
                    if (_isSelf) ...[
                      const SizedBox(height: 6),
                      Text(
                        'You can\u2019t change your own role — ask another admin.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.lg),

                    if (!_isSelf)
                      OutlinedButton.icon(
                        onPressed: _toggleBlocked,
                        icon: Icon(
                          customer.isBlocked
                              ? Icons.lock_open_rounded
                              : Icons.block_rounded,
                          size: 18,
                        ),
                        label: Text(
                          customer.isBlocked
                              ? 'Unblock Account'
                              : 'Block Account',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: customer.isBlocked
                              ? AppColors.success
                              : AppColors.error,
                          side: BorderSide(
                            color: customer.isBlocked
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: PrimaryButton(
                label: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _isSelf || _selectedRole == customer.role
                    ? null
                    : _saveRole,
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
        children: [
          SizedBox(
            width: 110,
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
