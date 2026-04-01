import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../features/profile/providers/profile_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(title: l10n.myOrders),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(l10n.couldNotLoadOrders, style: AppTextStyles.h4()),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(ordersProvider.notifier).load(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (orders) => orders.isEmpty
            ? const _EmptyOrders()
            : RefreshIndicator(
                onRefresh: () => ref.read(ordersProvider.notifier).load(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _OrderCard(order: orders[i]),
                ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isActive = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.outForDelivery;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber ?? order.id.substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.title(),
                      ),
                      const SizedBox(height: 3),
                      Text(_formatDate(order.createdAt),
                          style: AppTextStyles.caption()),
                    ],
                  ),
                ),
                StatusPill(
                  label: order.statusLabel,
                  bgColor: _statusBg(order.status),
                  textColor: _statusColor(order.status),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Text('₹${order.totalAmount.toInt()}',
                    style: AppTextStyles.title()),
                const Spacer(),
                if (isActive)
                  OutlinedButton(
                    onPressed: () => context.push(
                      AppRoutes.orderTracking
                          .replaceFirst(':orderId', order.id),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(120, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm + 2),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.trackOrder),
                  )
                else
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(minimumSize: const Size(110, 38)),
                    child: Text(AppLocalizations.of(context)!.reorder),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today, ${_time(dt)}';
    if (diff.inDays == 1) return 'Yesterday, ${_time(dt)}';
    return '${dt.day} ${_month(dt.month)}, ${_time(dt)}';
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

  Color _statusBg(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return const Color(0xFFFFF8E1);
      case OrderStatus.delivered: return const Color(0xFFE3F2FD);
      case OrderStatus.outForDelivery: return AppColors.greenSoft;
      case OrderStatus.preparing: return const Color(0xFFE3F2FD);
      case OrderStatus.confirmed: return const Color(0xFFFCE4EC);
      case OrderStatus.cancelled: return const Color(0xFFFFEBEE);
    }
  }

  Color _statusColor(OrderStatus s) {
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

// ─── Empty Orders ─────────────────────────────────────────────────────────────
class _EmptyOrders extends StatefulWidget {
  const _EmptyOrders();

  @override
  State<_EmptyOrders> createState() => _EmptyOrdersState();
}

class _EmptyOrdersState extends State<_EmptyOrders> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/lottie/no_order.webm');
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
            Text(AppLocalizations.of(context)!.noOrdersYet,
                style: AppTextStyles.h3(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.noOrdersSubtitle,
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
