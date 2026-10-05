import 'package:flutter/material.dart';

/// The set of colours that change between light and dark mode.
/// Everything else in [AppColors] (brand accents, status colours,
/// gradients) is identical in both modes.
class AppPalette {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color shadow;
  final Color primary;
  final Color primaryLight;
  final Color accentLight;
  final Color skeleton;

  /// Fill for solid buttons (white label on top) and snack bars.
  final Color buttonFill;
  final Color inverse;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.shadow,
    required this.primary,
    required this.primaryLight,
    required this.accentLight,
    required this.skeleton,
    required this.buttonFill,
    required this.inverse,
  });

  static const light = AppPalette(
    background: Color(0xFFFAFAFC),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFEEEEF2),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B6B80),
    textMuted: Color(0xFFA0A0B2),
    shadow: Color(0x1A1A1A2E),
    primary: Color(0xFF4B3FE4),
    primaryLight: Color(0xFFEDEBFF),
    accentLight: Color(0xFFFFE8E2),
    skeleton: Color(0xFFEDEDF2),
    buttonFill: Color(0xFF4B3FE4),
    inverse: Color(0xFF1A1A2E),
  );

  /// Deep navy-black with slightly lifted cards, soft off-white text and a
  /// lighter violet so brand-coloured text/icons stay readable on dark.
  static const dark = AppPalette(
    background: Color(0xFF0F0F17),
    surface: Color(0xFF1A1A25),
    border: Color(0xFF2C2C3B),
    textPrimary: Color(0xFFF1F1F7),
    textSecondary: Color(0xFFB7B7C9),
    textMuted: Color(0xFF8585A0),
    shadow: Color(0x66000000),
    primary: Color(0xFF7C72FF),
    primaryLight: Color(0xFF24214A),
    accentLight: Color(0xFF3A2220),
    skeleton: Color(0xFF262633),
    buttonFill: Color(0xFF6A5FF5),
    inverse: Color(0xFF2C2C3E),
  );
}

/// ShopVerse brand palette.
/// Primary: deep indigo-violet (premium, trustworthy)
/// Accent: warm coral (CTAs, discounts, energy)
///
/// The neutral colours (background, surface, text, border...) and the
/// primary violet are GETTERS that follow the current theme, so every
/// existing `AppColors.surface` / `AppColors.textPrimary` in the app
/// automatically turns dark in dark mode. [isDark] is kept in sync with
/// the active theme by `_ThemeSync` in main.dart.
class AppColors {
  AppColors._();

  static bool isDark = false;
  static AppPalette get _p => isDark ? AppPalette.dark : AppPalette.light;

  // Brand
  static Color get primary => _p.primary;
  static const Color primaryDark = Color(0xFF352DB0);
  static Color get primaryLight => _p.primaryLight;

  static const Color accent = Color(0xFFFF6B4A); // coral - CTAs / discounts
  static Color get accentLight => _p.accentLight;

  // Neutrals
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get border => _p.border;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

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
  static Color get shadow => _p.shadow;
  static Color get skeleton => _p.skeleton;
}
