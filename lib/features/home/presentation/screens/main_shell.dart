import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../providers/app_providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    void onNavTap(int index) {
      ref.read(bottomNavIndexProvider.notifier).state = index;
      switch (index) {
        case 0: context.go(AppRoutes.home); break;
        case 1: context.go(AppRoutes.categories); break;
        case 2: context.go(AppRoutes.cart); break;
        case 3: context.go(AppRoutes.profile); break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: S2BottomNav(
        currentIndex: currentIndex,
        cartCount: cartCount,
        onTap: onNavTap,
      ),
    );
  }
}
