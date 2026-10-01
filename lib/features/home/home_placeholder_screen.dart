import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Placeholder for Phase 2 (Home Screen: banners, categories, featured
/// products, best sellers, etc. — PRD Section 6). Kept minimal here so the
/// Phase 1 auth flow (Splash -> Onboarding -> Login/Register) is fully
/// navigable and demonstrable end-to-end.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            const SizedBox(height: 16),
            Text('You\u2019re in! 🎉', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Home screen (Phase 2) builds here next.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
