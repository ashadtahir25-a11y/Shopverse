import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography. Using 'Plus Jakarta Sans' for a modern,
/// friendly-but-premium commercial feel (headings) and 'Inter' for body.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  // Display / Headings
  static TextStyle h1 = _jakarta(size: 32, weight: FontWeight.w800, height: 1.2);
  static TextStyle h2 = _jakarta(size: 26, weight: FontWeight.w800, height: 1.25);
  static TextStyle h3 = _jakarta(size: 22, weight: FontWeight.w700, height: 1.3);
  static TextStyle h4 = _jakarta(size: 18, weight: FontWeight.w700, height: 1.3);

  // Body
  static TextStyle bodyLarge = _inter(size: 16, weight: FontWeight.w500, height: 1.5);
  static TextStyle bodyMedium = _inter(size: 14, weight: FontWeight.w500, height: 1.5);
  static TextStyle bodySmall = _inter(size: 12, weight: FontWeight.w500, height: 1.4);

  // Labels / Buttons
  static TextStyle buttonLarge = _jakarta(size: 16, weight: FontWeight.w700, color: Colors.white);
  static TextStyle buttonMedium = _jakarta(size: 14, weight: FontWeight.w700, color: Colors.white);

  static TextStyle caption = _inter(size: 11, weight: FontWeight.w500, color: AppColors.textMuted);

  static TextStyle price = _jakarta(size: 18, weight: FontWeight.w800, color: AppColors.textPrimary);
  static TextStyle priceStrike = _inter(
    size: 13,
    weight: FontWeight.w500,
    color: AppColors.strikePrice,
  ).copyWith(decoration: TextDecoration.lineThrough);

  static TextStyle link = _inter(size: 14, weight: FontWeight.w600, color: AppColors.primary);
}
