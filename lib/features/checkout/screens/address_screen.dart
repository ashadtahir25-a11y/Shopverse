import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/address_model.dart';
import '../providers/address_provider.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider);
    final selectedId = ref.watch(selectedAddressIdProvider) ?? (addresses.isNotEmpty ? addresses.first.id : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Delivery Address')),
      body: Column(
        children: [
          Expanded(
            child: addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No saved addresses', style: AppTextStyles.h4),
                        const SizedBox(height: 4),
                        Text('Add an address to continue', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppDimens.md),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final addr = addresses[i];
                      final selected = addr.id == selectedId;
                      return GestureDetector(
                        onTap: () => ref.read(selectedAddressIdProvider.notifier).state = addr.id,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: selected ? AppColors.primary : AppColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(addr.fullName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                                          child: Text(addr.label.display, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(addr.phone, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(addr.formatted, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                                onPressed: () => ref.read(addressProvider.notifier).remove(addr.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Column(
              children: [
                PrimaryButton(
                  label: '+ Add New Address',
                  outlined: true,
                  onPressed: () => context.push('/checkout/address/add'),
                ),
                const SizedBox(height: AppDimens.sm),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: (addresses.isEmpty || selectedId == null) ? null : () => context.push('/checkout/summary'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
