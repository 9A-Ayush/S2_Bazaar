import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final ProductModel? product;

  const ProductDetailScreen({super.key, required this.productId, this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    if (widget.product != null) {
      return _buildContent(context, widget.product!);
    }

    final productAsync = ref.watch(productProvider(widget.productId));

    return productAsync.when(
      data: (p) => _buildContent(context, p),
      loading: () => const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildContent(BuildContext context, ProductModel p) {
    final cart = ref.watch(cartProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero image
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.card,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 16, color: AppColors.text1),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.card,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.favorite_border,
                              size: 18, color: AppColors.primary),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppColors.surface,
                      child: Center(
                        child: Text(
                          p.categoryId == 'groceries' ? '🍅' : '🌾',
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    ),
                  ),
                ),

                // Details
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: AppTextStyles.h1()),
                                  const SizedBox(height: 4),
                                  Text('${p.unit} · Premium Quality',
                                      style: AppTextStyles.caption()),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${p.price.toInt()}',
                                    style: AppTextStyles.display(
                                        color: AppColors.primary)),
                                if (p.originalPrice != null)
                                  Text(
                                    '₹${p.originalPrice!.toInt()}',
                                    style: AppTextStyles.caption(
                                      color: AppColors.text3,
                                    ).copyWith(
                                        decoration:
                                            TextDecoration.lineThrough),
                                  ),
                                if (p.discountPercent != null)
                                  DiscountBadge(
                                    label:
                                        '${p.discountPercent!.toInt()}% OFF',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Rating
                        Row(
                          children: [
                            const Text('⭐',
                                style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('${p.rating}',
                                style: AppTextStyles.bodyBold()),
                            const SizedBox(width: 8),
                            Text('(${p.reviewCount} reviews)',
                                style: AppTextStyles.caption()),
                          ],
                        ),
                        const Divider(height: 28),

                        // Description
                        Text('About this product',
                            style: AppTextStyles.h4()),
                        const SizedBox(height: 8),
                        Text(
                          p.description ??
                              'Farm-fresh product sourced directly from local farmers. Premium quality guaranteed for best taste and nutrition.',
                          style: AppTextStyles.body(),
                        ),
                        const Divider(height: 28),

                        // Quantity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Quantity', style: AppTextStyles.h4()),
                            QuantityControl(
                              quantity: _qty,
                              onIncrement: () => setState(() => _qty++),
                              onDecrement: () => setState(
                                  () => _qty = (_qty - 1).clamp(1, 99)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky CTA ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.nav,
            ),
            child: Row(
              children: [
                // Cart icon button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border:
                        Border.all(color: AppColors.primary),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      for (int i = 0; i < _qty; i++) {
                        cart.addItem(p);
                      }
                      Navigator.pop(context);
                    },
                    child: Text('Add to Cart — ₹${(p.price * _qty).toInt()}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
