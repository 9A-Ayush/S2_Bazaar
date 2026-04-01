import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _offerAlerts = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(title: l10n.settings),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications section
          _SectionLabel(label: l10n.notifications),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: '🔔',
                iconBg: const Color(0xFFFFF3E0),
                label: l10n.pushNotifications,
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SwitchTile(
                icon: '📦',
                iconBg: AppColors.primarySoft,
                label: l10n.orderUpdates,
                value: _orderUpdates,
                onChanged: (v) => setState(() => _orderUpdates = v),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SwitchTile(
                icon: '🏷️',
                iconBg: AppColors.greenSoft,
                label: l10n.offersPromotions,
                value: _offerAlerts,
                onChanged: (v) => setState(() => _offerAlerts = v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Language section
          _SectionLabel(label: l10n.language),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _TapTile(
                icon: '🌐',
                iconBg: const Color(0xFFE8F5E9),
                label: l10n.changeLanguage,
                value: currentLocale.languageCode == 'hi' ? l10n.hindi : l10n.english,
                onTap: () => _showLanguagePicker(context, l10n, currentLocale),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // App info section
          _SectionLabel(label: l10n.appInfo),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: '📱',
                iconBg: const Color(0xFFE3F2FD),
                label: l10n.appVersion,
                value: '1.0.0',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _TapTile(
                icon: '📄',
                iconBg: AppColors.surface,
                label: l10n.privacyPolicy,
                onTap: () => _showInfo(context, l10n.privacyPolicy, l10n.privacyPolicyContent),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _TapTile(
                icon: '📋',
                iconBg: AppColors.surface,
                label: l10n.termsOfService,
                onTap: () => _showInfo(context, l10n.termsOfService, l10n.termsContent),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Danger zone
          _SectionLabel(label: l10n.account),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _TapTile(
                icon: '🚪',
                iconBg: AppColors.primarySoft,
                label: l10n.logout,
                labelColor: AppColors.primary,
                onTap: () => _logout(context, l10n),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(l10n.tagline,
                style: AppTextStyles.caption(color: AppColors.text3)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text(title, style: AppTextStyles.h4()),
        content: Text(content, style: AppTextStyles.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.close,
                  style: AppTextStyles.bodyBold(color: AppColors.primary))),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l10n, Locale current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.selectLanguage, style: AppTextStyles.h4()),
                ),
                _LanguageOption(
                  flag: '🇬🇧',
                  label: l10n.english,
                  selected: current.languageCode == 'en',
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                _LanguageOption(
                  flag: '🇮🇳',
                  label: l10n.hindi,
                  selected: current.languageCode == 'hi',
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('hi'));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text(l10n.logoutConfirmTitle, style: AppTextStyles.h4()),
        content: Text(l10n.logoutConfirmMessage, style: AppTextStyles.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.logout,
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(cartProvider.notifier).clearCart();
      await ref.read(authServiceProvider).signOut();
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.label(color: AppColors.text3));
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2)),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyBold())),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2)),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyBold())),
          Text(value, style: AppTextStyles.caption(color: AppColors.text2)),
        ],
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final String? value;
  final VoidCallback onTap;

  const _TapTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.labelColor,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2)),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 17))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyBold(
                      color: labelColor ?? AppColors.text1)),
            ),
            if (value != null)
              Text(value!, style: AppTextStyles.caption(color: AppColors.text2)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: AppTextStyles.bodyBold()),
      trailing: selected
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.radio_button_unchecked, color: AppColors.text3),
      onTap: onTap,
    );
  }
}
