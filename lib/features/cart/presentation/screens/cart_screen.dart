import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';
import '../../data/coupon_repository.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cartAsync = ref.watch(cartProvider);
    final cartItems = ref.watch(cartItemsProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);
    final appliedCoupon = ref.watch(appliedCouponProvider);

    void goBack() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.home);

    if (cartAsync.isLoading && cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: S2AppBar(title: l10n.myCart, onBack: goBack),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: S2AppBar(title: l10n.myCart, onBack: goBack),
        body: const _EmptyCart(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(
        title: l10n.myCart,
        onBack: goBack,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${cartNotifier.itemCount} ${l10n.items}',
                  style: AppTextStyles.captionBold(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ...cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CartItemCard(
                  item: item,
                  onIncrement: () => cartNotifier.addItem(item.product),
                  onDecrement: () => cartNotifier.removeItem(item.product.id),
                  onDelete: () => cartNotifier.deleteItem(item.product.id),
                ),
              )),
          const SizedBox(height: 4),
          _CouponRow(
            appliedCoupon: appliedCoupon,
            onRemove: () => ref.read(appliedCouponProvider.notifier).state = null,
          ),
          const SizedBox(height: 12),
          _PriceSummary(notifier: cartNotifier),
          const SizedBox(height: 14),
          PrimaryButton(
            label: l10n.placeOrder,
            subtitle: l10n.estDelivery,
            trailing: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            onPressed: () => context.push(AppRoutes.checkout),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Cart ───────────────────────────────────────────────────────────────
class _EmptyCart extends StatefulWidget {
  const _EmptyCart();

  @override
  State<_EmptyCart> createState() => _EmptyCartState();
}

class _EmptyCartState extends State<_EmptyCart> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/lottie/empty_cart.webm');
    _ctrl.initialize().then((_) {
      _ctrl.setLooping(true);
      _ctrl.setVolume(0);
      _ctrl.play();
    });
    _ctrl.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: _ctrl.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      child: AspectRatio(
                        aspectRatio: _ctrl.value.aspectRatio,
                        child: VideoPlayer(_ctrl),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text('Your cart is empty',
                style: AppTextStyles.h3(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Looks like you haven\'t added anything yet',
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
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.buyNow,
                    style: AppTextStyles.bodyBold(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart Item Card ───────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.primary),
      ),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                  child: Text('🍅', style: TextStyle(fontSize: 26))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.product.name,
                      style: AppTextStyles.bodyBold(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${item.product.unit} · ₹${item.product.price.toInt()}',
                      style: AppTextStyles.caption()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: QuantityControl(
                quantity: item.quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                axis: Axis.vertical,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coupon Row ───────────────────────────────────────────────────────────────
class _CouponRow extends ConsumerWidget {
  final CouponModel? appliedCoupon;
  final VoidCallback onRemove;

  const _CouponRow({required this.appliedCoupon, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appliedCoupon != null) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.greenSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.green),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.check_circle_outline, color: AppColors.green, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appliedCoupon!.code,
                      style: AppTextStyles.captionBold(color: AppColors.green)),
                  Text(appliedCoupon!.label,
                      style: AppTextStyles.label(color: AppColors.green)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.close, color: AppColors.green, size: 18),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        final subtotal = ref.read(cartSubtotalProvider);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _CouponSheet(subtotal: subtotal),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(AppLocalizations.of(context)!.applyCoupon,
                  style: AppTextStyles.caption(color: AppColors.text2)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

// ─── Coupon Sheet ─────────────────────────────────────────────────────────────
class _CouponSheet extends ConsumerStatefulWidget {
  final double subtotal;
  const _CouponSheet({required this.subtotal});

  @override
  ConsumerState<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<_CouponSheet> {
  final _ctrl = TextEditingController();
  bool _validating = false;
  String? _errorMsg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply(String code) async {
    if (code.trim().isEmpty) return;
    setState(() { _validating = true; _errorMsg = null; });

    final result = await ref
        .read(couponRepositoryProvider)
        .validate(code, widget.subtotal);

    if (!mounted) return;
    setState(() => _validating = false);

    if (result.isValid) {
      ref.read(appliedCouponProvider.notifier).state = result.coupon;
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${result.coupon!.code} applied — ${result.coupon!.label}'),
          backgroundColor: AppColors.green,
        ));
      }
    } else {
      setState(() {
        _errorMsg = switch (result.error!) {
          CouponValidationError.notFound => 'Invalid coupon code.',
          CouponValidationError.expired => 'This coupon has expired.',
          CouponValidationError.minOrderNotMet =>
            'Min order ₹${widget.subtotal < 1 ? '' : ''}. Add more items.',
          CouponValidationError.usageLimitReached =>
            'This coupon has reached its usage limit.',
          CouponValidationError.perUserLimitReached =>
            'You\'ve already used this coupon.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(activeCouponsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Apply Coupon', style: AppTextStyles.h3()),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      errorText: _errorMsg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    onSubmitted: _apply,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _validating ? null : () => _apply(_ctrl.text),
                    child: _validating
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Available Coupons',
                style: AppTextStyles.captionBold(color: AppColors.text2)),
            const SizedBox(height: 10),
            couponsAsync.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (coupons) => Column(
                mainAxisSize: MainAxisSize.min,
                children: coupons
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CouponTile(
                            coupon: c,
                            subtotal: widget.subtotal,
                            onApply: () => _apply(c.code),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coupon Tile ──────────────────────────────────────────────────────────────
class _CouponTile extends StatelessWidget {
  final CouponModel coupon;
  final double subtotal;
  final VoidCallback onApply;

  const _CouponTile(
      {required this.coupon, required this.subtotal, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final eligible = subtotal >= coupon.minOrderAmount;
    final discount = coupon.discountFor(subtotal);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: eligible ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: eligible
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border),
        boxShadow: eligible ? AppShadows.soft : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: eligible
                            ? AppColors.primarySoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                            color: eligible
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      child: Text(coupon.code,
                          style: AppTextStyles.captionBold(
                              color: eligible
                                  ? AppColors.primary
                                  : AppColors.text3)),
                    ),
                    if (eligible && discount > 0) ...[
                      const SizedBox(width: 8),
                      Text('Save ₹${discount.toInt()}',
                          style: AppTextStyles.captionBold(
                              color: AppColors.green)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(coupon.description ?? coupon.label,
                    style: AppTextStyles.caption()),
                Text(coupon.minOrderLabel,
                    style: AppTextStyles.label(
                        color: eligible
                            ? AppColors.text3
                            : AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: eligible ? onApply : null,
            child: Text(
              eligible ? 'APPLY' : 'N/A',
              style: AppTextStyles.captionBold(
                  color: eligible ? AppColors.primary : AppColors.text3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Price Summary ────────────────────────────────────────────────────────────
class _PriceSummary extends ConsumerWidget {
  final CartNotifier notifier;
  const _PriceSummary({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupon = ref.watch(appliedCouponProvider);
    final couponDiscount = ref.watch(couponDiscountProvider);
    final total = ref.watch(cartTotalProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.priceSummary, style: AppTextStyles.h4()),
          const SizedBox(height: 14),
          _SumRow(label: AppLocalizations.of(context)!.subtotal, value: '₹${notifier.subtotal.toInt()}'),
          const SizedBox(height: 10),
          _SumRow(label: AppLocalizations.of(context)!.delivery, value: '₹${notifier.deliveryFee.toInt()}'),
          if (notifier.discount > 0) ...[
            const SizedBox(height: 10),
            _SumRow(
              label: AppLocalizations.of(context)!.discount,
              value: '− ₹${notifier.discount.toInt()}',
              valueColor: AppColors.green,
            ),
          ],
          if (coupon != null && couponDiscount > 0) ...[
            const SizedBox(height: 10),
            _SumRow(
              label: 'Coupon (${coupon.code})',
              value: '− ₹${couponDiscount.toInt()}',
              valueColor: AppColors.green,
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.total, style: AppTextStyles.title()),
              Text('₹${total.toInt()}', style: AppTextStyles.priceLarge()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SumRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body()),
        Text(value,
            style: AppTextStyles.captionBold(
                color: valueColor ?? AppColors.text1)),
      ],
    );
  }
}
