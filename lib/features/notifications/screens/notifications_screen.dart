// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.orderPlaced => Icons.receipt_long_rounded,
        NotificationType.orderShipped => Icons.local_shipping_rounded,
        NotificationType.orderDelivered => Icons.check_circle_rounded,
        NotificationType.orderCancelled => Icons.cancel_rounded,
        NotificationType.returnUpdate => Icons.assignment_return_rounded,
        NotificationType.promotion => Icons.local_offer_rounded,
        NotificationType.priceDrop => Icons.trending_down_rounded,
        NotificationType.priceIncrease => Icons.trending_up_rounded,
        NotificationType.newProduct => Icons.fiber_new_rounded,
        NotificationType.wishlistAvailable => Icons.favorite_rounded,
      };

  Color _colorFor(NotificationType type) => switch (type) {
        NotificationType.orderPlaced || NotificationType.orderShipped => AppColors.info,
        NotificationType.orderDelivered => AppColors.success,
        NotificationType.orderCancelled => AppColors.error,
        NotificationType.returnUpdate => AppColors.warning,
        NotificationType.promotion || NotificationType.priceDrop => AppColors.accent,
        NotificationType.priceIncrease => AppColors.warning,
        NotificationType.newProduct => AppColors.primary,
        NotificationType.wishlistAvailable => AppColors.primary,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: AppTextStyles.h4),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimens.md),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final color = _colorFor(n.type);
                return GestureDetector(
                  onTap: () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: n.read ? AppColors.surface : AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_iconFor(n.type), color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(n.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                                  if (!n.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(n.message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(_timeAgo(n.timestamp), style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 40).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
              },
            ),
    );
  }
}
