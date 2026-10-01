import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/surface_card.dart';

const _faqs = [
  ('How do I track my order?', 'Go to Profile > My Orders, select your order, then tap "Track Order" to see its live status and delivery timeline.'),
  ('What payment methods are accepted?', 'We accept Cash on Delivery, Credit/Debit Cards, Bank Transfer, and select mobile wallets.'),
  ('How do I return a product?', 'Once your order is marked "Delivered", open the order details and tap "Return / Refund" next to the item.'),
  ('How long does delivery take?', 'Standard delivery takes 3–5 business days; Express delivery takes 1–2 business days.'),
  ('Can I cancel my order?', 'Yes — orders can be cancelled any time before they are shipped, from the order details screen.'),
];

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.md),
        children: [
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Contact Us',
                  onTap: () => context.push('/help-support/contact'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'My Tickets',
                  onTap: () => context.push('/help-support/tickets'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),

          Text('Frequently Asked Questions', style: AppTextStyles.h4),
          const SizedBox(height: AppDimens.md),
          ..._faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2)),

          const SizedBox(height: AppDimens.lg),
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Still need help?', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Our support team typically responds within 24 hours.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('support@shopverse.pk', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('+92 21 1234 5678', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                PrimaryButton(label: 'Open a Support Ticket', onPressed: () => context.push('/help-support/contact')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        borderRadius: AppDimens.radiusMd,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd))),
            collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd))),
            title: Text(question, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(answer, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))],
          ),
        ),
      ),
    );
  }
}
