import 'package:flutter/material.dart';

class BannerData {
  final String id;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String iconKey;
  final String gradientKey;
  final String? imageUrl;
  final String? targetCategoryId;
  final bool isActive;
  final int sortOrder;

  const BannerData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.iconKey,
    required this.gradientKey,
    this.imageUrl,
    this.targetCategoryId,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Curated icon presets — kept as a fixed set (rather than a free
  /// picker) so every banner reliably renders something sensible, same
  /// reasoning as ProductCategory.icons.
  static const Map<String, IconData> icons = {
    'fire': Icons.local_fire_department_rounded,
    'sparkle': Icons.auto_awesome_rounded,
    'delivery': Icons.local_shipping_rounded,
    'gift': Icons.card_giftcard_rounded,
    'tag': Icons.sell_rounded,
    'star': Icons.star_rounded,
    'bolt': Icons.bolt_rounded,
    'heart': Icons.favorite_rounded,
  };

  /// Curated gradient presets — a real color picker is more UI than a
  /// promo-banner editor needs; swatches keep every banner on-brand.
  static const Map<String, List<Color>> gradients = {
    'purple': [Color(0xFF5B4FF0), Color(0xFF4B3FE4)],
    'orange': [Color(0xFFFF8A65), Color(0xFFFF6B4A)],
    'teal': [Color(0xFF16C79A), Color(0xFF0FA37F)],
    'pink': [Color(0xFFFF6B9D), Color(0xFFE94D8A)],
    'blue': [Color(0xFF3E9DFF), Color(0xFF2B7FE0)],
    'gold': [Color(0xFFE0A93B), Color(0xFFC98A1F)],
  };

  IconData get icon => icons[iconKey] ?? Icons.local_offer_rounded;
  List<Color> get gradient => gradients[gradientKey] ?? gradients['purple']!;

  BannerData copyWith({
    String? title,
    String? subtitle,
    String? ctaLabel,
    String? iconKey,
    String? gradientKey,
    String? imageUrl,
    bool clearImage = false,
    String? targetCategoryId,
    bool clearTargetCategory = false,
    bool? isActive,
    int? sortOrder,
  }) {
    return BannerData(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      iconKey: iconKey ?? this.iconKey,
      gradientKey: gradientKey ?? this.gradientKey,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      targetCategoryId: clearTargetCategory
          ? null
          : (targetCategoryId ?? this.targetCategoryId),
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'title': title,
    'subtitle': subtitle,
    'ctaLabel': ctaLabel,
    'iconKey': iconKey,
    'gradientKey': gradientKey,
    'imageUrl': imageUrl,
    'targetCategoryId': targetCategoryId,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };

  factory BannerData.fromFirestore(String id, Map<String, dynamic> data) {
    return BannerData(
      id: id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      ctaLabel: data['ctaLabel'] as String? ?? 'Shop Now',
      iconKey: data['iconKey'] as String? ?? 'tag',
      gradientKey: data['gradientKey'] as String? ?? 'purple',
      imageUrl: data['imageUrl'] as String?,
      targetCategoryId: data['targetCategoryId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

const List<BannerData> mockBanners = [
  BannerData(
    id: 'season-sale',
    title: 'Season Sale',
    subtitle: 'Up to 40% off on electronics',
    ctaLabel: 'Shop Now',
    iconKey: 'fire',
    gradientKey: 'purple',
    sortOrder: 0,
  ),
  BannerData(
    id: 'new-arrivals',
    title: 'New Arrivals',
    subtitle: 'Fresh styles just dropped',
    ctaLabel: 'Explore',
    iconKey: 'sparkle',
    gradientKey: 'orange',
    sortOrder: 1,
  ),
  BannerData(
    id: 'free-delivery',
    title: 'Free Delivery',
    subtitle: 'On orders above Rs. 3,000',
    ctaLabel: 'Learn More',
    iconKey: 'delivery',
    gradientKey: 'teal',
    sortOrder: 2,
  ),
];
