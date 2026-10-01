import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/product_model.dart';

class VariantSelector extends StatelessWidget {
  final VariantAttribute attribute;
  final String? selectedOptionId;
  final void Function(String optionId) onSelected;

  const VariantSelector({
    super.key,
    required this.attribute,
    required this.selectedOptionId,
    required this.onSelected,
  });

  bool get _isColor => attribute.name.toLowerCase() == 'color';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(attribute.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: attribute.options.map((opt) {
            final selected = opt.id == selectedOptionId;
            if (_isColor && opt.colorHex != null) {
              final color = Color(int.parse(opt.colorHex!.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () => onSelected(opt.id),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 18, color: _contrastColor(color))
                      : null,
                ),
              );
            }
            return GestureDetector(
              onTap: () => onSelected(opt.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                ),
                child: Text(
                  opt.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _contrastColor(Color bg) {
    final brightness = ThemeData.estimateBrightnessForColor(bg);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}
