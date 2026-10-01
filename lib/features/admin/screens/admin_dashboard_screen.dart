import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminGuard(
      child: AdminShell(activeLabel: 'Dashboard', child: _DashboardContent()),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final totalRevenue = ref.watch(totalRevenueProvider);
    final totalOrders = ref.watch(totalOrdersCountProvider);
    final pendingOrders = ref.watch(pendingOrdersCountProvider);
    final totalCustomers = ref.watch(totalCustomersCountProvider);
    final totalProducts = ref.watch(totalProductsCountProvider);
    final lowStock = ref.watch(lowStockProductsCountProvider);
    final pendingReturns = ref.watch(pendingReturnsCountProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On narrow (mobile/drawer) layouts, fit exactly 2 stat cards per
          // row instead of the fixed 220px width overflowing/looking cramped.
          final isNarrow = constraints.maxWidth < 700;
          final cardWidth = isNarrow
              ? (constraints.maxWidth - AppDimens.md) / 2
              : 220.0;
          final horizontalPadding = isNarrow ? AppDimens.md : AppDimens.xl;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppDimens.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(
                  'Welcome back, ${profile.name}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.xl),

                Wrap(
                  spacing: AppDimens.md,
                  runSpacing: AppDimens.md,
                  children: [
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.payments_outlined,
                      label: 'Total Sales',
                      value: totalRevenue.when(
                        data: (v) => 'Rs. ${v.toStringAsFixed(0)}',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.success,
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.receipt_long_outlined,
                      label: 'Total Orders',
                      value: totalOrders.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.pending_actions_outlined,
                      label: 'Pending Orders',
                      value: pendingOrders.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.warning,
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.people_outline_rounded,
                      label: 'Total Customers',
                      value: totalCustomers.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.info,
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.inventory_2_outlined,
                      label: 'Total Products',
                      value: totalProducts.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.warning_amber_rounded,
                      label: 'Low Stock',
                      value: lowStock.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.error,
                    ),
                    _StatCard(
                      width: cardWidth,
                      icon: Icons.assignment_return_outlined,
                      label: 'Pending Returns',
                      value: pendingReturns.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                      color: AppColors.accent,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.xl),
                SurfaceCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'More to come',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Product management, order management, customer management, coupons, '
                          'reviews moderation, returns processing, and sales charts are being built '
                          'out incrementally — this dashboard already reflects live data from '
                          'Firestore and will grow section by section.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double width;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(value, style: AppTextStyles.h3),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
