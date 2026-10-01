import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/address_model.dart';
import '../providers/address_provider.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _postalController = TextEditingController();
  final _instructionsController = TextEditingController();
  AddressLabel _label = AddressLabel.home;

  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final address = Address(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      area: _areaController.text.trim(),
      postalCode: _postalController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      label: _label,
    );

    try {
      await ref.read(addressProvider.notifier).add(address);
      ref.read(selectedAddressIdProvider.notifier).state = address.id;
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save address. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add New Address')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Full Name',
                  hint: 'e.g. Ayesha Khan',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Phone',
                  hint: '03XX-XXXXXXX',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Address',
                  hint: 'House #, street, landmark',
                  controller: _addressController,
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'City',
                        hint: 'Karachi',
                        controller: _cityController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Area',
                        hint: 'Clifton',
                        controller: _areaController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Postal Code',
                  hint: '75600',
                  controller: _postalController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  label: 'Additional Instructions (optional)',
                  hint: 'e.g. Leave with security guard',
                  controller: _instructionsController,
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  'Label',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: AddressLabel.values.map((l) {
                    final selected = l == _label;
                    return ChoiceChip(
                      label: Text(l.display),
                      selected: selected,
                      onSelected: (_) => setState(() => _label = l),
                      selectedColor: AppColors.primaryLight,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimens.xl),
                PrimaryButton(
                  label: 'Save Address',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
