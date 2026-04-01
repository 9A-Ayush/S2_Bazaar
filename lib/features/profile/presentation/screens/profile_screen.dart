import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../providers/app_providers.dart';
import '../../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final activeCountAsync = ref.watch(activeOrderCountProvider);

    Future<void> logout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xxl)),
          title: Text('Logout', style: AppTextStyles.h4()),
          content: Text('Are you sure you want to logout?',
              style: AppTextStyles.body()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: AppTextStyles.bodyBold(color: AppColors.text2)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Logout',
                  style: AppTextStyles.bodyBold(color: AppColors.primary)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        ref.read(cartProvider.notifier).clearCart();
        await ref.read(authServiceProvider).signOut();
        // Router listener handles navigation
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: profileAsync.when(
                loading: () => _ProfileHeroSkeleton(),
                error: (_, __) => _ProfileHeroSkeleton(),
                data: (user) => _ProfileHero(
                  name: user?.name.isNotEmpty == true ? user!.name : 'My Profile',
                  phone: user?.phone ?? '',
                  avatarUrl: user?.avatarUrl,
                  onEdit: () => context.push(AppRoutes.editProfile),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('MY ACCOUNT',
                    style: AppTextStyles.label(color: AppColors.text3)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _MenuCard(
                  items: [
                    _MenuItem(
                      icon: '👤',
                      iconBg: AppColors.primarySoft,
                      label: 'Personal Info',
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                    _MenuItem(
                      icon: '🛍️',
                      iconBg: const Color(0xFFFFF3E0),
                      label: 'My Orders',
                      badge: activeCountAsync.when(
                        data: (c) => c > 0 ? '$c Active' : null,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      onTap: () => context.push(AppRoutes.orderHistory),
                    ),
                    _MenuItem(
                      iconWidget: Image.asset(
                        'assets/icons/location.png',
                        width: 20,
                        height: 20,
                      ),
                      iconBg: const Color(0xFFE3F2FD),
                      label: 'Saved Addresses',
                      onTap: () => context.push(AppRoutes.savedAddresses),
                    ),
                    _MenuItem(
                      icon: '💳',
                      iconBg: AppColors.greenSoft,
                      label: 'Payments & Wallet',
                      onTap: () => context.push(AppRoutes.payments),
                    ),
                    _MenuItem(
                      icon: '🔔',
                      iconBg: const Color(0xFFFFF3E0),
                      label: 'Notifications',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _MenuCard(
                  items: [
                    _MenuItem(
                      icon: '⚙️',
                      iconBg: AppColors.surface,
                      label: 'Settings',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    _MenuItem(
                      icon: '🚪',
                      iconBg: AppColors.primarySoft,
                      label: 'Logout',
                      labelColor: AppColors.primary,
                      onTap: logout,
                      showChevron: false,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final String name;
  final String phone;
  final String? avatarUrl;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEBEE), Colors.white],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? Image.network(avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Text('👤', style: TextStyle(fontSize: 34))))
                      : const Center(child: Text('👤', style: TextStyle(fontSize: 34))),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.h2()),
          const SizedBox(height: 4),
          if (phone.isNotEmpty) Text(phone, style: AppTextStyles.caption()),
        ],
      ),
    );
  }
}

class _ProfileHeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEBEE), Colors.white],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 120, height: 16, decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          )),
          const SizedBox(height: 8),
          Container(width: 80, height: 12, decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          )),
        ],
      ),
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _MenuRow(item: item),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _MenuItem item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
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
                color: item.iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Center(
                child: item.iconWidget ??
                    Text(item.icon!, style: const TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: AppTextStyles.bodyBold(
                    color: item.labelColor ?? AppColors.text1),
              ),
            ),
            if (item.badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.badge!,
                  style: AppTextStyles.captionBold(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (item.showChevron)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String? icon;
  final Widget? iconWidget;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final String? badge;
  final VoidCallback? onTap;
  final bool showChevron;

  const _MenuItem({
    this.icon,
    this.iconWidget,
    required this.iconBg,
    required this.label,
    this.labelColor,
    this.badge,
    this.onTap,
    this.showChevron = true,
  }) : assert(icon != null || iconWidget != null);
}
