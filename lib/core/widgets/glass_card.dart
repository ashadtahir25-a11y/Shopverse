import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';

/// A frosted-glass ("glassmorphism") container: blurred backdrop,
/// translucent white fill, soft border, subtle shadow. Designed to sit on
/// top of a colorful/gradient background (see [AuroraBackground]) — on a
/// plain white background the blur has nothing to catch, so pair it with
/// a gradient or image behind it for the intended effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.lg),
    this.borderRadius = AppDimens.radiusXl,
    this.blurSigma = 18,
    this.opacity = 0.14,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A small frosted-glass chip/button — used for icon buttons floating over
/// gradient headers (e.g. back button, notification bell).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconColor = Colors.white,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2.6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: iconColor, size: size * 0.48),
            ),
          ),
        ),
      ),
    );
  }
}
