import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A bordered, rounded "card" surface — use this instead of
/// `Container(decoration: BoxDecoration(color: ...))` whenever the content
/// inside contains a ListTile, ExpansionTile, InkWell, or anything else
/// that paints ink splashes.
///
/// WHY THIS EXISTS: a plain colored Container/DecoratedBox sits between
/// the ListTile and the app's root Material widget, so Flutter can't find
/// a nearby Material to paint the tap ripple/background onto — it throws
/// "ListTile background color or ink splashes may be invisible" and the
/// splash silently fails to render. Wrapping the color fill in its own
/// [Material] widget (as done here) gives ink effects a proper home.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final Border? border;
  final Clip clipBehavior;

  const SurfaceCard({
    super.key,
    required this.child,
    this.borderRadius = AppDimens.radiusLg,
    this.color,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: Material(
          color: color ?? AppColors.surface,
          child: child,
        ),
      ),
    );
  }
}
