// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/data/seed_service.dart';
import '../../../core/providers/currency_provider.dart';
import '../../admin/widgets/admin_security_dialog.dart';
import '../../notifications/providers/notification_prefs_provider.dart';
import '../../profile/providers/user_profile_provider.dart';
import '../../profile/widgets/change_password_sheet.dart';
import '../widgets/change_email_dialog.dart';
import '../widgets/change_phone_dialog.dart';
import '../widgets/delete_account_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSeeding = false;

  Future<void> _seedCatalog() async {
    if (ref.read(userProfileProvider).role != 'admin') return;
    setState(() => _isSeeding = true);
    try {
      await seedService.seedCatalog();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo catalog seeded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Seeding failed: $e')));
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _showCurrencyPicker() {
    final current = ref.read(currencyProvider).selected.code;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Currency', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: current,
                onChanged: (v) {
                  if (v == null) return;
                  ref.read(currencyProvider.notifier).selectCode(v);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  children: [
                    for (final c in kCurrencies)
                      RadioListTile<String>(
                        value: c.code,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${c.code} — ${c.name}', style: AppTextStyles.bodyMedium),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prices are shown in the chosen currency while you browse and in your cart, using the latest exchange rate. '
                'Checkout, orders and receipts always use PKR — the amount you are actually charged.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changePassword() {
    // The admin account goes through the personal-key protected flow.
    if (ref.read(userProfileProvider).role == 'admin') {
      showAdminSecurityDialog(context);
    } else {
      showChangePasswordSheet(context);
    }
  }

  void _showThemePicker() {
    final currentMode = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            RadioGroup<ThemeMode>(
              groupValue: currentMode,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setMode(v!);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Light'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Dark'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Match System'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final currentLanguage = ref.read(appLanguageProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            RadioGroup<AppLanguage>(
              groupValue: currentLanguage,
              onChanged: (v) {
                ref.read(appLanguageProvider.notifier).setLanguage(v!);
                Navigator.pop(context);
              },
              child: Column(
                children: AppLanguage.values
                    .map(
                      (lang) => RadioListTile<AppLanguage>(
                        value: lang,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          lang.label,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: layout direction switches to right-to-left for Urdu. Full text translation is a separate upcoming pass.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() => showDeleteAccountDialog(context);

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'Match System',
  };

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);
    final prefs = ref.watch(notificationPrefsProvider);
    final currency = ref.watch(currencyProvider);
    final isAdmin = ref.watch(userProfileProvider).role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.md),
        children: [
          _SectionLabel('Notification Preferences'),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: prefs.orderUpdates,
                onChanged: (v) => ref.read(notificationPrefsProvider.notifier).set(kPrefOrderUpdates, v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Order Updates',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Status changes, delivery updates',
                  style: AppTextStyles.caption,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: prefs.promotions,
                onChanged: (v) => ref.read(notificationPrefsProvider.notifier).set(kPrefPromotions, v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Promotions & Offers',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Sales, coupons, new arrivals',
                  style: AppTextStyles.caption,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: prefs.priceDrops,
                onChanged: (v) => ref.read(notificationPrefsProvider.notifier).set(kPrefPriceDrops, v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Price Drops',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'When a product\u2019s price changes',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.lg),
          _SectionLabel('Preferences'),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Language',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                onTap: _showLanguagePicker,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Currency',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(currency.note, style: AppTextStyles.caption),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency.selected.code,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                onTap: _showCurrencyPicker,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Theme',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _themeLabel(themeMode),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                onTap: _showThemePicker,
              ),
            ],
          ),

          const SizedBox(height: AppDimens.lg),
          _SectionLabel('Account'),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Change Password',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
                onTap: _changePassword,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Change Email',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
                onTap: () => showChangeEmailDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Change Phone',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
                onTap: () => showChangePhoneDialog(context),
              ),
            ],
          ),

          if (isAdmin) ...[
          const SizedBox(height: AppDimens.lg),
          _SectionLabel('Developer'),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Seed Demo Catalog',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Pushes demo categories/products into Firestore (safe to re-run)',
                  style: AppTextStyles.caption,
                ),
                trailing: _isSeeding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                onTap: _isSeeding ? null : _seedCatalog,
              ),
            ],
          ),
          ],

          const SizedBox(height: AppDimens.xl),
          PrimaryButton(
            label: 'Delete Account',
            outlined: true,
            onPressed: _confirmDeleteAccount,
          ),
          const SizedBox(height: AppDimens.lg),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
        child: Column(children: children),
      ),
    );
  }
}
