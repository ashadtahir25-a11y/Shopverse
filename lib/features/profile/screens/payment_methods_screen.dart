import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

/// Which payment options the store offers. Only Cash on Delivery is
/// actually processed today; the online options can be chosen at
/// checkout but real payment processing isn't connected yet — the screen
/// says so plainly instead of implying cards can be saved/charged.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  static const _methods = [
    (Icons.payments_outlined, 'Cash on Delivery', 'Pay in cash when your order arrives.', true),
    (Icons.credit_card_rounded, 'Credit / Debit Card', 'Online card payments are coming soon.', false),
    (Icons.account_balance_wallet_outlined, 'Mobile Wallet', 'JazzCash / EasyPaisa are coming soon.', false),
    (Icons.account_balance_outlined, 'Bank Transfer', 'Online bank payments are coming soon.', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.md),
        children: [
          Text('Available at checkout', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimens.md),
          for (final m in _methods)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: Icon(m.$1, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.$2, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(m.$3, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(m.$4 ? Icons.check_circle_rounded : Icons.schedule_rounded, color: m.$4 ? AppColors.success : AppColors.textMuted, size: 22),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
