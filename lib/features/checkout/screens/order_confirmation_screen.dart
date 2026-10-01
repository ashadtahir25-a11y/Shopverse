import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/aurora_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/routes/app_router.dart';
import '../../orders/providers/orders_provider.dart';

/// Receives the newly placed order's real `id` (not just its
/// human-readable `orderNumber`) so "Track Order" can navigate to that
/// specific order's tracking page — the previous version only had the
/// display number and had nowhere real to send the user, so "Track
/// Order" was wired to just go Home.
class OrderConfirmationScreen extends ConsumerWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Any "Added to cart" toast from a moment ago (e.g. Buy Now) shouldn't
    // still be floating over this success screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });

    final order = ref.watch(ordersProvider.notifier).getById(orderId);
    final orderNumber = order?.orderNumber ?? orderId;
    final date = order?.date ?? DateTime.now();
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Scaffold(
      body: AuroraBackground(
        colors: const [Color(0xFF16C79A), Color(0xFF0FA37F)],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              children: [
                const Spacer(),
                Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    )
                    .animate()
                    .scale(duration: 450.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
                const SizedBox(height: AppDimens.lg),
                Text(
                  'Order Placed!',
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                const SizedBox(height: 6),
                Text(
                  'Thank you for shopping with ShopVerse',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
                const SizedBox(height: AppDimens.xl),

                GlassCard(
                      opacity: 0.94,
                      blurSigma: 22,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      child: Column(
                        children: [
                          _Row(label: 'Order Number', value: orderNumber),
                          const Divider(height: 20),
                          _Row(label: 'Order Date', value: dateStr),
                          const Divider(height: 20),
                          _Row(
                            label: 'Payment Status',
                            value: 'Pending',
                            valueColor: AppColors.warning,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),

                const Spacer(),
                PrimaryButton(
                  label: 'Track Order',
                  onPressed: () =>
                      context.push('${AppRoutes.orders}/$orderId/track'),
                ),
                const SizedBox(height: AppDimens.sm),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue Shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
