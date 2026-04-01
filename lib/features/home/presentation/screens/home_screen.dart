import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/location_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _HomeHeader(cartCount: cartCount)),

            // ── Search Bar ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: GestureDetector(
                  onTap: () {},
                  child: const S2SearchBar(readOnly: true),
                ),
              ),
            ),

            // ── Promo Banner ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: _PromoBanner(),
              ),
            ),

            // ── Categories ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: SectionHeader(
                  title: 'Shop by Category',
                  onSeeAll: () => context.go(AppRoutes.categories),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                child: _CategoryGrid(),
              ),
            ),

            // ── Featured Products ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: SectionHeader(
                  title: 'Featured Products',
                  onSeeAll: () => context.go(AppRoutes.categories),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: _ProductGrid(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HomeHeader extends ConsumerWidget {
  final int cartCount;

  const _HomeHeader({required this.cartCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);

    String locationLabel;
    Color dotColor;
    switch (loc.status) {
      case LocationStatus.inRange:
        locationLabel = 'Delivering to you';
        dotColor = AppColors.green;
        break;
      case LocationStatus.outOfRange:
        locationLabel = 'Outside delivery zone';
        dotColor = Colors.orange;
        break;
      case LocationStatus.loading:
        locationLabel = 'Checking location…';
        dotColor = AppColors.text3;
        break;
      default:
        locationLabel = 'Siwan, Bihar';
        dotColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.map),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELIVER TO',
                    style: AppTextStyles.label(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(locationLabel, style: AppTextStyles.title()),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              S2IconButton(
                bgColor: AppColors.primarySoft,
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.primary, size: 20),
                onTap: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Promo Banner ─────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.categories),
      child: Container(
        height: 156,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Content
            Positioned(
              left: 20,
              top: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('🔥 MEGA DEAL',
                        style: AppTextStyles.label(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Text('Up to 40% OFF',
                      style: AppTextStyles.h1(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('On groceries & essentials',
                      style:
                          AppTextStyles.caption(color: Colors.white.withOpacity(0.8))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('Shop Now →',
                        style: AppTextStyles.captionBold(
                            color: AppColors.primary)),
                  ),
                ],
              ),
            ),

            // Emoji illustration
            Positioned(
              right: 16,
              top: 8,
              bottom: 8,
              child: Container(
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🥗', style: TextStyle(fontSize: 56)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Grid ────────────────────────────────────────────────────────────
class _CategoryGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);

    return catsAsync.when(
      data: (cats) {
        if (cats.isEmpty) {
          return const Center(child: Text('No categories found.'));
        }
        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _CategoryCard(
              category: cats[i],
              onTap: () => context.go(AppRoutes.categories),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: Color(category.color),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: AppTextStyles.label(color: Color(category.textColor)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Grid ─────────────────────────────────────────────────────────────
class _ProductGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(featuredProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No featured products.'));
        }
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductCard(product: products[i]),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider.notifier);
    ref.watch(cartItemsProvider); // rebuild when cart changes
    final qty = cart.quantityOf(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
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
                  if (product.badge != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: DiscountBadge(
                        label: product.badge!,
                        color: product.badge == 'BESTSELLER'
                            ? AppColors.primarySoft
                            : AppColors.greenSoft,
                        textColor: product.badge == 'BESTSELLER'
                            ? AppColors.primary
                            : AppColors.green,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toInt()}',
                        style: AppTextStyles.price(),
                      ),
                      const Spacer(),
                      if (qty > 0)
                        QuantityControl(
                          quantity: qty,
                          onIncrement: () => cart.addItem(product),
                          onDecrement: () => cart.removeItem(product.id),
                        )
                      else
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
      ),
    );
  }
}

