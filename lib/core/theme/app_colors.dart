import 'package:flutter/material.dart';

/// ShopVerse brand palette.
/// Primary: deep indigo-violet (premium, trustworthy)
/// Accent: warm coral (CTAs, discounts, energy)
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4B3FE4); // deep indigo-violet
  static const Color primaryDark = Color(0xFF352DB0);
  static const Color primaryLight = Color(0xFFEDEBFF);

  static const Color accent = Color(0xFFFF6B4A); // coral - CTAs / discounts
  static const Color accentLight = Color(0xFFFFE8E2);

  // Neutrals
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEEEEF2);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textMuted = Color(0xFFA0A0B2);

  // Status
  static const Color success = Color(0xFF16C79A);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF3E9DFF);

  // Ratings
  static const Color star = Color(0xFFFFB020);

  // Price
  static const Color discount = Color(0xFFFF6B4A);
  static const Color strikePrice = Color(0xFFA0A0B2);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF5B4FF0),
    Color(0xFF4B3FE4),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF8A65),
    Color(0xFFFF6B4A),
  ];

  // Overlays
  static const Color shadow = Color(0x1A1A1A2E);
  static const Color skeleton = Color(0xFFEDEDF2);
}
