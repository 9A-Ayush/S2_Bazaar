import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';
import '../../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(title: 'Wishlist'),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) => products.isEmpty
            ? const _EmptyWishlist()
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(wishlistProductsProvider.notifier).load(),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _WishlistCard(product: products[i]),
                ),
              ),
      ),
    );
  }
}

class _WishlistCard extends ConsumerWidget {
  final ProductModel product;
  const _WishlistCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + remove heart
          Stack(
            children: [
              GestureDetector(
                onTap: () => context.push(
                    '/product/${product.id}', extra: product),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    topRight: Radius.circular(AppRadius.xl),
                  ),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: Center(
                      child: Text(
                        product.categoryId == 'groceries' ? '🍅' : '🌾',
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(wishlistProvider.notifier)
                        .toggle(product.id);
                    ref
                        .read(wishlistProductsProvider.notifier)
                        .removeLocally(product.id);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Icon(Icons.favorite,
                        color: AppColors.primary, size: 16),
                  ),
                ),
              ),
            ],
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: AppTextStyles.captionBold(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(product.unit,
                    style: AppTextStyles.label(color: AppColors.text3)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('₹${product.price.toInt()}',
                        style: AppTextStyles.price()),
                    const Spacer(),
                    AddToCartButton(
                      onTap: () => cart.addItem(product),
                      size: 28,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤍', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text('Your wishlist is empty',
                style: AppTextStyles.h3(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Save products you love by tapping the heart icon',
                style: AppTextStyles.body(color: AppColors.text2),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
                child: Text('Browse Products',
                    style: AppTextStyles.bodyBold(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
