import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shows the user's real uploaded photo (a Cloudinary URL, once they've
/// uploaded one) or, by default, a colored circle with their initials.
///
/// Uses Flutter's built-in Image.network (not a third-party caching
/// package) deliberately — on Flutter Web, image-loading failures from
/// third-party cache packages don't always surface through their error
/// callbacks reliably, which can leave a blank/black circle forever.
/// Image.network's loadingBuilder/errorBuilder are core framework APIs
/// with more predictable behavior across web renderers.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 72,
    this.backgroundColor,
    this.foregroundColor,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl!,
          key: ValueKey(avatarUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _initialsCircle();
          },
          errorBuilder: (context, error, stackTrace) => _initialsCircle(),
        ),
      );
    }
    return _initialsCircle();
  }

  Widget _initialsCircle() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: foregroundColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
