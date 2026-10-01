import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../checkout/models/coupon_model.dart';
import '../providers/admin_coupons_provider.dart';

/// Shows the Add/Edit Coupon dialog. Pass an existing [coupon] to edit
/// it, or omit it to create a new one.
Future<void> showCouponFormDialog(BuildContext context, {Coupon? coupon}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CouponFormDialog(coupon: coupon),
  );
}

class _CouponFormDialog extends StatefulWidget {
  final Coupon? coupon;
  const _CouponFormDialog({this.coupon});

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _valueController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _maxDiscountController;

  CouponType _type = CouponType.percentage;
  DateTime _expiry = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeController = TextEditingController(text: c?.code ?? '');
    _valueController = TextEditingController(
      text: c != null ? c.value.toStringAsFixed(0) : '',
    );
    _minOrderController = TextEditingController(
      text: c != null ? c.minOrder.toStringAsFixed(0) : '0',
    );
    _maxDiscountController = TextEditingController(
      text: c?.maxDiscount != null ? c!.maxDiscount!.toStringAsFixed(0) : '',
    );
    _type = c?.type ?? CouponType.percentage;
    _expiry = c?.expiry ?? DateTime.now().add(const Duration(days: 30));
    _isActive = c?.active ?? true;
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim().toUpperCase();

    setState(() => _isSaving = true);
    try {
      if (!_isEditing) {
        final exists = await adminCouponsService.codeExists(code);
        if (exists) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A coupon with code "$code" already exists'),
            ),
          );
          return;
        }
      }

      final coupon = Coupon(
        code: code,
        type: _type,
        value: double.tryParse(_valueController.text.trim()) ?? 0,
        minOrder: double.tryParse(_minOrderController.text.trim()) ?? 0,
        maxDiscount: _maxDiscountController.text.trim().isEmpty
            ? null
            : double.tryParse(_maxDiscountController.text.trim()),
        expiry: _expiry,
        active: _isActive,
      );
      await adminCouponsService.saveCoupon(coupon);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Coupon updated' : 'Coupon created'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save coupon. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Coupon' : 'Add Coupon',
                      style: AppTextStyles.h4,
                    ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Coupon Code',
                        hint: 'e.g. WELCOME10',
                        controller: _codeController,
                        enabled: !_isEditing,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimens.md),

                      Text(
                        'Discount Type',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<CouponType>(
                        segments: const [
                          ButtonSegment(
                            value: CouponType.percentage,
                            label: Text('Percentage %'),
                          ),
                          ButtonSegment(
                            value: CouponType.fixed,
                            label: Text('Fixed Rs.'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (s) =>
                            setState(() => _type = s.first),
                      ),
                      const SizedBox(height: AppDimens.md),

                      AppTextField(
                        label: _type == CouponType.percentage
                            ? 'Discount Percentage (%)'
                            : 'Discount Amount (Rs.)',
                        hint: _type == CouponType.percentage
                            ? 'e.g. 10'
                            : 'e.g. 500',
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || double.tryParse(v.trim()) == null)
                            ? 'Enter a valid number'
                            : null,
                      ),
                      const SizedBox(height: AppDimens.md),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Minimum Order (Rs.)',
                              hint: '0',
                              controller: _minOrderController,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  (v == null ||
                                      double.tryParse(v.trim()) == null)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppDimens.md),
                          Expanded(
                            child: AppTextField(
                              label: 'Max Discount (optional)',
                              hint: 'No cap',
                              controller: _maxDiscountController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.md),

                      Text(
                        'Expiry Date',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickExpiry,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        label: Text(
                          '${_expiry.day}/${_expiry.month}/${_expiry.year}',
                        ),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),

                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Active',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Customers can use it at checkout when on',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Create Coupon',
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
