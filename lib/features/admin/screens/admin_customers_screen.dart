import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/admin_customers_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import '../widgets/customer_detail_dialog.dart';

class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminGuard(
      child: AdminShell(activeLabel: 'Customers', child: _CustomersContent()),
    );
  }
}

class _CustomersContent extends ConsumerStatefulWidget {
  const _CustomersContent();

  @override
  ConsumerState<_CustomersContent> createState() => _CustomersContentState();
}

class _CustomersContentState extends ConsumerState<_CustomersContent> {
  final _searchController = TextEditingController();
  bool _staffOnly = false;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersProvider);
    final query = _searchController.text.trim().toLowerCase();

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
                Text('Customers', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.md),
                Wrap(
                  spacing: AppDimens.md,
                  runSpacing: AppDimens.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isNarrow ? double.infinity : 340,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search name or email...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 14,
                          ),
                        ),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Staff only'),
                      selected: _staffOnly,
                      onSelected: (v) => setState(() => _staffOnly = v),
                      selectedColor: AppColors.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: customersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load customers',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (customers) {
                      var filtered = customers;
                      if (_staffOnly) {
                        filtered = filtered.where((c) => c.isStaff).toList();
                      }
                      if (query.isNotEmpty) {
                        filtered = filtered
                            .where(
                              (c) =>
                                  c.name.toLowerCase().contains(query) ||
                                  c.email.toLowerCase().contains(query),
                            )
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No customers found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _CustomerRow(
                          customer: filtered[i],
                          onTap: () =>
                              showCustomerDetailDialog(context, filtered[i]),
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

class _CustomerRow extends StatelessWidget {
  final AdminCustomer customer;
  final VoidCallback onTap;

  const _CustomerRow({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.sm),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: customer.avatarUrl,
                name: customer.name,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      customer.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (customer.isBlocked)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Blocked',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (customer.isStaff)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.role,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
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
