import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/wishlist_provider.dart';

class WishlistHeartButton extends ConsumerWidget {
  final String productId;
  final double size;

  const WishlistHeartButton({
    super.key,
    required this.productId,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWishlisted = ref.watch(wishlistProvider).whenOrNull(
          data: (ids) => ids.contains(productId),
        ) ??
        false;

    return GestureDetector(
      onTap: () => ref.read(wishlistProvider.notifier).toggle(productId),
      child: Container(
        width: size + 12,
        height: size + 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.soft,
        ),
        child: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          color: isWishlisted ? AppColors.primary : AppColors.text3,
          size: size,
        ),
      ),
    );
  }
}
