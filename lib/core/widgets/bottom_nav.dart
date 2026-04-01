import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class S2BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const S2BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'HOME'),
    _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'CATEG.'),
    _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'CART'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFILE'),
  ];

  // Cart is index 2
  static const _cartIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final isActive = i == currentIndex;
                  final showBadge = i == _cartIndex && cartCount > 0;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isActive ? _items[i].activeIcon : _items[i].icon,
                                  size: 18,
                                  color: isActive ? Colors.white : AppColors.text3,
                                ),
                                if (showBadge)
                                  Positioned(
                                    top: -5,
                                    right: -7,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      constraints: const BoxConstraints(
                                          minWidth: 14, minHeight: 14),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        cartCount > 99 ? '99+' : '$cartCount',
                                        style: TextStyle(
                                          color: isActive
                                              ? AppColors.primary
                                              : Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _items[i].label,
                              style: AppTextStyles.navLabel(
                                color: isActive ? Colors.white : AppColors.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
