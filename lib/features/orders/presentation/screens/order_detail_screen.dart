import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../features/profile/providers/profile_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    void goBack() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.orderHistory);

    return ordersAsync.when(
      loading: () => Scaffold(
        backgroundColor: Colors.white,
        appBar: S2AppBar(title: 'Order Details', onBack: goBack),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: Colors.white,
        appBar: S2AppBar(title: 'Order Details', onBack: goBack),
        body: const Center(child: Text('Could not load order')),
      ),
      data: (orders) {
        final order = orders.where((o) => o.id == orderId).firstOrNull;
        if (order == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: S2AppBar(title: 'Order Details', onBack: goBack),
            body: const Center(child: Text('Order not found')),
          );
        }
        return _OrderDetailView(order: order, onBack: goBack);
      },
    );
  }
}

class _OrderDetailView extends ConsumerWidget {
  final OrderModel order;
  final VoidCallback onBack;
  const _OrderDetailView({required this.order, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel = order.status == OrderStatus.pending;
    final isActive = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.outForDelivery;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(title: 'Order Details', onBack: onBack),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── Order Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.orderNumber ?? order.id.substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.h4(),
                      ),
                    ),
                    _StatusPill(status: order.status, label: order.statusLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_formatDate(order.createdAt),
                    style: AppTextStyles.caption()),
                const SizedBox(height: 4),
                Text(
                  'Payment: ${order.paymentMethod.toUpperCase()}',
                  style: AppTextStyles.caption(color: AppColors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Items ─────────────────────────────────────────────────────────
          Text('Items', style: AppTextStyles.h4()),
          const SizedBox(height: 10),
          if (order.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text('No item details available',
                  style: AppTextStyles.body(color: AppColors.text2)),
            )
          else
            ...order.items.map((item) => _OrderItemRow(item: item)),
          const SizedBox(height: 16),

          // ── Price Summary ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Paid', style: AppTextStyles.title()),
                    Text('₹${order.totalAmount.toInt()}',
                        style: AppTextStyles.priceLarge()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Actions ───────────────────────────────────────────────────────
          if (isActive)
            OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.orderTracking.replaceFirst(':orderId', order.id),
              ),
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text('Track Order'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          if (canCancel) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _confirmCancel(context, ref),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text('Cancel Order', style: AppTextStyles.h4()),
        content: Text('Are you sure you want to cancel this order?',
            style: AppTextStyles.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No',
                style: AppTextStyles.bodyBold(color: AppColors.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, Cancel',
                style: AppTextStyles.bodyBold(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(ordersProvider.notifier).cancelOrder(order.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully')),
          );
          context.canPop() ? context.pop() : context.go(AppRoutes.orderHistory);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to cancel order. Try again.')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today, ${_time(dt)}';
    if (diff.inDays == 1) return 'Yesterday, ${_time(dt)}';
    return '${dt.day} ${_month(dt.month)} ${dt.year}, ${_time(dt)}';
  }

  String _month(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItemModel item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: AppTextStyles.bodyBold(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${item.product.unit} · ₹${item.product.price.toInt()} each',
                    style: AppTextStyles.caption()),
              ],
            ),
          ),
          Text('x${item.quantity}',
              style: AppTextStyles.captionBold(color: AppColors.text2)),
          const SizedBox(width: 12),
          Text('₹${item.totalPrice.toInt()}', style: AppTextStyles.title()),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final OrderStatus status;
  final String label;
  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: label,
      bgColor: _bg(status),
      textColor: _fg(status),
    );
  }

  Color _bg(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return const Color(0xFFFFF8E1);
      case OrderStatus.delivered: return const Color(0xFFE3F2FD);
      case OrderStatus.outForDelivery: return AppColors.greenSoft;
      case OrderStatus.preparing: return const Color(0xFFE3F2FD);
      case OrderStatus.confirmed: return const Color(0xFFFCE4EC);
      case OrderStatus.cancelled: return const Color(0xFFFFEBEE);
    }
  }

  Color _fg(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return const Color(0xFFF57F17);
      case OrderStatus.delivered: return const Color(0xFF1565C0);
      case OrderStatus.outForDelivery: return AppColors.green;
      case OrderStatus.preparing: return const Color(0xFF1565C0);
      case OrderStatus.confirmed: return const Color(0xFF880E4F);
      case OrderStatus.cancelled: return AppColors.primary;
    }
  }
}
