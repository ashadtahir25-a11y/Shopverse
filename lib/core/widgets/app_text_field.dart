import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final void Function(String)? onChanged;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isMultiline = !widget.isPassword && widget.maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscure : false,
          keyboardType: widget.keyboardType,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            alignLabelWithHint: isMultiline,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? (isMultiline
                      // Multi-line fields (e.g. Address): pin the icon to
                      // the first line, next to the hint text, instead of
                      // floating in the vertical middle of the box.
                      ? Align(
                          alignment: Alignment.topCenter,
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Icon(
                              widget.prefixIcon,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: AppColors.textMuted,
                        ))
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
