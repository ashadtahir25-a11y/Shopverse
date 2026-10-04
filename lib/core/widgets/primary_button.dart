import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Standard commercial-grade CTA button with gradient fill,
/// loading state, and disabled state — used across the whole app
/// (Login, Checkout, Place Order, Add to Cart, etc.)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    if (outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: AppDimens.buttonHeight,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          child: _buildChild(color: AppColors.primary),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: AppDimens.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: disabled ? AppColors.textMuted.withValues(alpha: 0.3) : null,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            onTap: disabled ? null : onPressed,
            child: Center(child: _buildChild(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildChild({required Color color}) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          // Flexible + ellipsis: when this button is given a narrow
          // explicit width (e.g. width: 90/109/220 elsewhere in the
          // app) and the icon+label combo doesn't fit, this lets the
          // label shrink/truncate instead of throwing a RenderFlex
          // overflow error.
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.buttonLarge.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }
    return Text(
      label,
      style: AppTextStyles.buttonLarge.copyWith(color: color),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
