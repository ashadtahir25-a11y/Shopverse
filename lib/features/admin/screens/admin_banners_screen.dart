import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/surface_card.dart';
import '../../home/widgets/banner_model.dart';
import '../providers/admin_banners_provider.dart';
import '../widgets/admin_guard.dart';
import '../widgets/admin_shell.dart';
import '../widgets/banner_form_dialog.dart';

class AdminBannersScreen extends StatelessWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      section: 'Banners',
      child: const AdminShell(activeLabel: 'Banners', child: _BannersContent()),
    );
  }
}

class _BannersContent extends ConsumerWidget {
  const _BannersContent();

  Future<void> _confirmDelete(BuildContext context, BannerData banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: const Text('Delete Banner'),
        content: Text(
          'Are you sure you want to permanently delete "${banner.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await adminBannersService.deleteBanner(banner.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Banner deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final padding = isNarrow ? AppDimens.md : AppDimens.xl;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimens.md,
                  runSpacing: AppDimens.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Banners', style: AppTextStyles.h2),
                    ElevatedButton.icon(
                      onPressed: () => showBannerFormDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Banner'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Shown on the Home screen in order (lowest sort order first)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                Expanded(
                  child: bannersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Couldn\u2019t load banners',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    data: (banners) {
                      if (banners.isEmpty) {
                        return Center(
                          child: Text(
                            'No banners yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: banners.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _BannerRow(
                          banner: banners[i],
                          onEdit: () =>
                              showBannerFormDialog(context, banner: banners[i]),
                          onDelete: () => _confirmDelete(context, banners[i]),
                          onToggleActive: () => adminBannersService.setActive(
                            banners[i],
                            !banners[i].isActive,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  final BannerData banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _BannerRow({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final preview = Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                gradient: banner.imageUrl == null
                    ? LinearGradient(
                        colors: banner.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: banner.imageUrl != null
                  ? Image.network(
                      banner.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        banner.icon,
                        color: AppColors.textMuted,
                        size: 26,
                      ),
                    )
                  : Icon(banner.icon, color: Colors.white, size: 26),
            );
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  banner.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Order: ${banner.sortOrder}${banner.targetCategoryId != null ? ' · Links to category' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            );
            final statusBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (banner.isActive ? AppColors.success : AppColors.textMuted)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                banner.isActive ? 'active' : 'inactive',
                style: AppTextStyles.caption.copyWith(
                  color: banner.isActive
                      ? AppColors.success
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    banner.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  tooltip: banner.isActive ? 'Deactivate' : 'Activate',
                  onPressed: onToggleActive,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      preview,
                      const SizedBox(width: 12),
                      Expanded(child: info),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [statusBadge, const Spacer(), actions]),
                ],
              );
            }

            return Row(
              children: [
                preview,
                const SizedBox(width: 12),
                Expanded(child: info),
                statusBadge,
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
