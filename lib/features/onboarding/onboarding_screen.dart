import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/primary_button.dart';
import 'onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool get _isLast => _currentIndex == onboardingPages.length - 1;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppDimens.md,
                  top: AppDimens.sm,
                ),
                child: TextButton(
                  onPressed: _isLast ? null : _completeOnboarding,
                  child: Text(
                    AppStrings.skip,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _isLast
                          ? Colors.transparent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final page = onboardingPages[index];
                  // LayoutBuilder + scroll view: on short phones or with a
                  // large system font the fixed 260px illustration plus the
                  // text used to overflow the page (yellow/black stripes).
                  // Now the illustration shrinks to fit, and as a last
                  // resort the page itself can scroll.
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final art = (constraints.maxHeight * 0.42)
                          .clamp(150.0, 260.0)
                          .toDouble();
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.lg,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                    width: art,
                                    height: art,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(48),
                                      boxShadow: [
                                        BoxShadow(
                                          color: page.gradient.last.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 30,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(48),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: page.gradient,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                page.icon,
                                                color: Colors.white,
                                                size: art * 0.35,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 14,
                                            right: 14,
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                page.icon,
                                                color: page.gradient.last,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    curve: Curves.easeOutBack,
                                  ),
                              const SizedBox(height: AppDimens.xl),
                              Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.h2,
                                  )
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 350.ms)
                                  .slideY(begin: 0.2, end: 0),
                              const SizedBox(height: AppDimens.sm),
                              Text(
                                    page.description,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 250.ms, duration: 350.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _pageController,
              count: onboardingPages.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.border,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: PrimaryButton(
                label: _isLast ? AppStrings.getStarted : AppStrings.next,
                onPressed: () {
                  if (_isLast) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
