import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _order = MockData.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => MockData.orders.first,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(
        title: 'Track Order',
        actions: [
          S2IconButton(
            bgColor: AppColors.primarySoft,
            icon: const Icon(Icons.headphones_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── Order Info Card ───────────────────────────────────────────────
          _OrderInfoCard(order: _order!),
          const SizedBox(height: 16),

          // ── Status Timeline ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Status', style: AppTextStyles.h4()),
                const SizedBox(height: 18),
                _buildTimeline(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Delivery Agent Card ───────────────────────────────────────────
          _DeliveryAgentCard(),
          const SizedBox(height: 16),

          // ── Map placeholder ───────────────────────────────────────────────
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🗺️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('Live tracking coming soon',
                      style: TextStyle(color: AppColors.text2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      _TrackStep(
        label: 'Order Confirmed',
        time: 'Today, 2:30 PM',
        status: _StepStatus.done,
      ),
      _TrackStep(
        label: 'Preparing Your Order',
        time: 'Today, 2:35 PM',
        status: _StepStatus.done,
      ),
      _TrackStep(
        label: 'Out for Delivery',
        time: 'Today, 3:10 PM · In progress',
        status: _StepStatus.active,
      ),
      _TrackStep(
        label: 'Delivered',
        time: 'Pending',
        status: _StepStatus.pending,
      ),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + line
            Column(
              children: [
                _StepDot(status: step.status, pulse: _pulse),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: step.status == _StepStatus.done
                        ? AppColors.primary
                        : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: AppTextStyles.bodyBold(
                        color: step.status == _StepStatus.pending
                            ? AppColors.text3
                            : AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.time,
                      style: AppTextStyles.caption(
                        color: step.status == _StepStatus.active
                            ? AppColors.primary
                            : AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Step Dot ─────────────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final _StepStatus status;
  final Animation<double> pulse;

  const _StepDot({required this.status, required this.pulse});

  @override
  Widget build(BuildContext context) {
    if (status == _StepStatus.active) {
      return AnimatedBuilder(
        animation: pulse,
        builder: (_, __) => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3 * (pulse.value - 1)),
                blurRadius: 8 * pulse.value,
                spreadRadius: 2 * (pulse.value - 1),
              ),
            ],
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 12),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: status == _StepStatus.done
            ? AppColors.primary
            : AppColors.surface,
        shape: BoxShape.circle,
        border: status == _StepStatus.pending
            ? Border.all(color: AppColors.border, width: 2)
            : null,
      ),
      child: status == _StepStatus.done
          ? const Icon(Icons.check, color: Colors.white, size: 12)
          : null,
    );
  }
}

// ─── Order Info Card ──────────────────────────────────────────────────────────
class _OrderInfoCard extends StatelessWidget {
  final OrderModel order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order.id}', style: AppTextStyles.title()),
              StatusPill(
                label: order.statusLabel,
                bgColor: AppColors.greenSoft,
                textColor: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaChip(icon: '📦', label: '3 items'),
              const SizedBox(width: 16),
              _MetaChip(icon: '⏱', label: '30–45 min'),
              const SizedBox(width: 16),
              _MetaChip(icon: '💰', label: '₹${order.totalAmount.toInt()}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption()),
      ],
    );
  }
}

// ─── Delivery Agent Card ──────────────────────────────────────────────────────
class _DeliveryAgentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
                color: AppColors.surface, shape: BoxShape.circle),
            child: const Center(
              child: Text('🧑', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Raju Sharma', style: AppTextStyles.bodyBold()),
                Text('Delivery Partner · ⭐ 4.8',
                    style: AppTextStyles.caption()),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_outlined,
                  color: AppColors.green, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enums ────────────────────────────────────────────────────────────────────
enum _StepStatus { done, active, pending }

class _TrackStep {
  final String label;
  final String time;
  final _StepStatus status;

  const _TrackStep(
      {required this.label, required this.time, required this.status});
}
