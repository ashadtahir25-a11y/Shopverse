import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final String imageSeed;
  final List<Color> gradient;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.imageSeed,
    required this.gradient,
  });
}

final List<OnboardingPageData> onboardingPages = [
  const OnboardingPageData(
    title: AppStrings.onboardTitle1,
    description: AppStrings.onboardDesc1,
    icon: Icons.travel_explore_rounded,
    imageSeed: 'shopverse-discover',
    gradient: [Color(0xFF5B4FF0), Color(0xFF4B3FE4)],
  ),
  const OnboardingPageData(
    title: AppStrings.onboardTitle2,
    description: AppStrings.onboardDesc2,
    icon: Icons.shopping_bag_rounded,
    imageSeed: 'shopverse-shopping',
    gradient: [Color(0xFFFF8A65), Color(0xFFFF6B4A)],
  ),
  const OnboardingPageData(
    title: AppStrings.onboardTitle3,
    description: AppStrings.onboardDesc3,
    icon: Icons.verified_user_rounded,
    imageSeed: 'shopverse-payment',
    gradient: [Color(0xFF16C79A), Color(0xFF0FA37F)],
  ),
  const OnboardingPageData(
    title: AppStrings.onboardTitle4,
    description: AppStrings.onboardDesc4,
    icon: Icons.local_shipping_rounded,
    imageSeed: 'shopverse-delivery',
    gradient: [Color(0xFF3E9DFF), Color(0xFF2E7FDB)],
  ),
];
