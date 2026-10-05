import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimens.dart';

/// Both themes come from ONE builder fed with a palette, so light and dark
/// can never drift apart: every component (app bar, inputs, sheets, dialogs,
/// chips, switches...) is styled once and simply picks up the palette.
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(AppPalette.light, Brightness.light);
  static final ThemeData dark = _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final roundedBorder = BorderRadius.circular(14);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      error: AppColors.error,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      fontFamily: AppTextStyles.bodyMedium.fontFamily,
      iconTheme: IconThemeData(color: p.textPrimary),

      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: AppTextStyles.h4.copyWith(color: p.textPrimary),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1.copyWith(color: p.textPrimary),
        displayMedium: AppTextStyles.h2.copyWith(color: p.textPrimary),
        displaySmall: AppTextStyles.h3.copyWith(color: p.textPrimary),
        headlineSmall: AppTextStyles.h4.copyWith(color: p.textPrimary),
        titleMedium: AppTextStyles.bodyLarge.copyWith(color: p.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: p.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: p.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: p.textSecondary),
        labelLarge: AppTextStyles.buttonLarge,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.buttonFill,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.buttonLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: p.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.buttonMedium.copyWith(color: p.primary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: AppTextStyles.bodyMedium,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: p.textMuted),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        border: OutlineInputBorder(borderRadius: roundedBorder, borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(borderRadius: roundedBorder, borderSide: BorderSide(color: p.border)),
        focusedBorder: OutlineInputBorder(borderRadius: roundedBorder, borderSide: BorderSide(color: p.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: roundedBorder, borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: roundedBorder, borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        iconColor: p.textPrimary,
        textColor: p.textPrimary,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textMuted,
        selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.primaryLight,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: p.primary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.inverse,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        actionTextColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.h4.copyWith(color: p.textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: p.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTextStyles.bodyMedium.copyWith(color: p.textPrimary),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : (isDark ? p.textMuted : null),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.buttonFill : (isDark ? p.border : null),
        ),
      ),
    );
  }
}
