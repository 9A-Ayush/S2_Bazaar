import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../../../providers/app_providers.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../providers/service_area_provider.dart';

// ─── Selected address provider (scoped to checkout) ──────────────────────────
final _selectedAddressProvider =
    StateProvider<AddressModel?>((ref) => null);

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final cartItems = ref.watch(cartItemsProvider);
    ref.watch(cartProvider);
    final payMethod = ref.watch(paymentMethodProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final selectedAddress = ref.watch(_selectedAddressProvider);
    final serviceState = ref.watch(serviceAreaProvider);

    // Auto-select default address + trigger service check when addresses load
    ref.listen(addressesProvider, (_, next) {
      next.whenData((list) {
        if (ref.read(_selectedAddressProvider) == null && list.isNotEmpty) {
          final def = list.firstWhere(
            (a) => a.isDefault,
            orElse: () => list.first,
          );
          ref.read(_selectedAddressProvider.notifier).state = def;
          // Trigger service area check for the auto-selected address
          ref.read(serviceAreaProvider.notifier).checkWithAddress(def);
        }
      });
    });

    // Re-check when selected address changes
    ref.listen(_selectedAddressProvider, (prev, next) {
      if (next != null && next.id != prev?.id) {
        ref.read(serviceAreaProvider.notifier).checkWithAddress(next);
      }
    });

    final displayAddress = selectedAddress ??
        addressesAsync.whenOrNull(
          data: (list) => list.isEmpty
              ? null
              : list.firstWhere((a) => a.isDefault,
                  orElse: () => list.first),
        );

    final canOrder = displayAddress != null &&
        serviceState.status == ServiceCheckStatus.available;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(title: 'Checkout'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // ── Delivery Address ─────────────────────────────────────────
                _SectionTitle(
                  title: 'Delivery Address',
                  action: 'Change',
                  onAction: () => _showAddressPicker(context, ref),
                ),
                const SizedBox(height: 10),
                addressesAsync.when(
                  loading: () => _AddressCardSkeleton(),
                  error: (_, __) => _NoAddressCard(
                    onAdd: () => context.push(AppRoutes.savedAddresses),
                  ),
                  data: (list) => list.isEmpty
                      ? _NoAddressCard(
                          onAdd: () =>
                              context.push(AppRoutes.savedAddresses),
                        )
                      : _AddressCard(address: displayAddress ?? list.first),
                ),
                const SizedBox(height: 10),

                // ── Service Area Banner ──────────────────────────────────────
                if (displayAddress != null)
                  _ServiceAreaBanner(
                    state: serviceState,
                    onChangeAddress: () =>
                        _showAddressPicker(context, ref),
                  ),
                const SizedBox(height: 20),

                // ── Payment Method ───────────────────────────────────────────
                const _SectionTitle(title: 'Payment Method'),
                const SizedBox(height: 10),
                _PaymentOption(
                  icon: Icons.smartphone_outlined,
                  label: 'UPI / PhonePe / GPay',
                  method: PaymentMethod.upi,
                  selected: payMethod == PaymentMethod.upi,
                  onTap: () => ref
                      .read(paymentMethodProvider.notifier)
                      .state = PaymentMethod.upi,
                ),
                const SizedBox(height: 8),
                _PaymentOption(
                  icon: Icons.credit_card_outlined,
                  label: 'Credit / Debit Card',
                  method: PaymentMethod.card,
                  selected: payMethod == PaymentMethod.card,
                  onTap: () => ref
                      .read(paymentMethodProvider.notifier)
                      .state = PaymentMethod.card,
                ),
                const SizedBox(height: 8),
                _PaymentOption(
                  icon: Icons.money_outlined,
                  label: 'Cash on Delivery (COD)',
                  method: PaymentMethod.cod,
                  selected: payMethod == PaymentMethod.cod,
                  onTap: () => ref
                      .read(paymentMethodProvider.notifier)
                      .state = PaymentMethod.cod,
                ),
                const SizedBox(height: 20),

                // ── Order Summary ────────────────────────────────────────────
                const _SectionTitle(title: 'Order Summary'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    children: [
                      _SumRow(
                        'Subtotal (${cartItems.length} items)',
                        '₹${cartNotifier.subtotal.toInt()}',
                      ),
                      const SizedBox(height: 10),
                      _SumRow(
                        'Delivery fee',
                        '₹${cartNotifier.deliveryFee.toInt()}',
                      ),
                      if (cartNotifier.discount > 0) ...[
                        const SizedBox(height: 10),
                        _SumRow(
                          'Discount',
                          '- ₹${cartNotifier.discount.toInt()}',
                          valueColor: AppColors.green,
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Payable',
                              style: AppTextStyles.title()),
                          Text('₹${cartNotifier.total.toInt()}',
                              style: AppTextStyles.priceLarge()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Confirm CTA ───────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.nav,
            ),
            child: PrimaryButton(
              label: canOrder
                  ? 'Confirm & Pay'
                  : serviceState.isLoading
                      ? 'Checking delivery...'
                      : 'Not Available in Your Area',
              isLoading: serviceState.isLoading,
              subtitle: canOrder
                  ? '₹${cartNotifier.total.toInt()} · ${_payLabel(payMethod)}'
                  : null,
              trailing: canOrder
                  ? const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18)
                  : null,
              onPressed: canOrder
                  ? () {
                      ref.read(cartProvider.notifier).clearCart();
                      context.push(AppRoutes.orderTracking
                          .replaceFirst(':orderId', 'S2-20483'));
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressPicker(BuildContext context, WidgetRef ref) {
    final addresses =
        ref.read(addressesProvider).valueOrNull ?? [];
    if (addresses.isEmpty) {
      context.push(AppRoutes.savedAddresses);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddressPickerSheet(
        addresses: addresses,
        selected: ref.read(_selectedAddressProvider),
        onSelect: (a) {
          ref.read(_selectedAddressProvider.notifier).state = a;
          Navigator.pop(ctx);
        },
        onAddNew: () {
          Navigator.pop(ctx);
          context.push(AppRoutes.savedAddresses);
        },
      ),
    );
  }

  String _payLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cod:
        return 'COD';
    }
  }
}

// ─── Service Area Banner ──────────────────────────────────────────────────────
class _ServiceAreaBanner extends StatelessWidget {
  final ServiceAreaState state;
  final VoidCallback onChangeAddress;

  const _ServiceAreaBanner({
    required this.state,
    required this.onChangeAddress,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ServiceCheckStatus.idle => const SizedBox.shrink(),
      ServiceCheckStatus.loading => _Banner(
          color: const Color(0xFFFFF8E1),
          border: const Color(0xFFF9A825),
          icon: '🔍',
          title: 'Checking delivery availability...',
          subtitle: 'Verifying if we serve your area',
          showSpinner: true,
        ),
      ServiceCheckStatus.available => _Banner(
          color: AppColors.greenSoft,
          border: AppColors.green,
          icon: '✅',
          title: 'Delivery available!',
          subtitle:
              '${state.result?.areaName ?? state.result?.city ?? 'Your area'} · ${state.result?.distanceKm?.toStringAsFixed(1)} km from store',
        ),
      ServiceCheckStatus.unavailable => _Banner(
          color: AppColors.primarySoft,
          border: AppColors.primary,
          icon: '❌',
          title: 'We don\'t deliver here yet',
          subtitle:
              'This address is outside our service area. Please use a different delivery address.',
          actions: [
            _BannerAction(
                label: 'Change Address',
                icon: Icons.edit_location_alt_outlined,
                onTap: onChangeAddress),
          ],
        ),
      ServiceCheckStatus.error => _Banner(
          color: const Color(0xFFFFF3E0),
          border: Colors.orange,
          icon: '⚠️',
          title: 'Could not verify address',
          subtitle: state.error ?? 'Please try a different delivery address.',
          actions: [
            _BannerAction(
                label: 'Change Address',
                icon: Icons.edit_location_alt_outlined,
                onTap: onChangeAddress),
          ],
        ),
    };
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final Color border;
  final String icon;
  final String title;
  final String subtitle;
  final bool showSpinner;
  final List<_BannerAction> actions;

  const _Banner({
    required this.color,
    required this.border,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showSpinner = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showSpinner)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.text2),
                )
              else
                Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTextStyles.bodyBold()),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(subtitle,
                style: AppTextStyles.caption(), maxLines: 2),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: actions
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: a.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(a.icon, size: 14, color: AppColors.text1),
                                const SizedBox(width: 4),
                                Text(a.label,
                                    style: AppTextStyles.captionBold()),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BannerAction(
      {required this.label, required this.icon, required this.onTap});
}

// ─── Address Picker Sheet ─────────────────────────────────────────────────────
class _AddressPickerSheet extends StatelessWidget {
  final List<AddressModel> addresses;
  final AddressModel? selected;
  final ValueChanged<AddressModel> onSelect;
  final VoidCallback onAddNew;

  const _AddressPickerSheet({
    required this.addresses,
    required this.selected,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Select Delivery Address', style: AppTextStyles.h4()),
          const SizedBox(height: 16),
          ...addresses.map((a) {
            final isSelected = selected?.id == a.id;
            return GestureDetector(
              onTap: () => onSelect(a),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm + 2),
                      ),
                      child: const Center(
                          child: Image(
                            image: AssetImage('assets/icons/location.png'),
                            width: 20,
                            height: 20,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(a.label,
                                  style: AppTextStyles.bodyBold()),
                              if (a.isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSoft,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                  ),
                                  child: Text('Default',
                                      style: AppTextStyles.label(
                                          color: AppColors.green)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (a.fullName.isNotEmpty)
                            Text(a.fullName,
                                style: AppTextStyles.captionBold(
                                    color: AppColors.text2)),
                          Text(a.fullAddress,
                              style: AppTextStyles.caption()),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onAddNew,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primary,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Add New Address',
                      style: AppTextStyles.bodyBold(
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address Card ─────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: const Center(
                child: Image(
                  image: AssetImage('assets/icons/location.png'),
                  width: 22,
                  height: 22,
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label, style: AppTextStyles.bodyBold()),
                    if (address.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('Default',
                            style: AppTextStyles.label(
                                color: AppColors.green)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (address.fullName.isNotEmpty)
                  Text(address.fullName,
                      style: AppTextStyles.captionBold(
                          color: AppColors.text2)),
                if (address.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(address.phone,
                      style:
                          AppTextStyles.caption(color: AppColors.text2)),
                ],
                const SizedBox(height: 2),
                Text(address.fullAddress,
                    style: AppTextStyles.caption()),
                if (address.landmark != null &&
                    address.landmark!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Landmark: ${address.landmark}',
                      style: AppTextStyles.caption(
                          color: AppColors.text2)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAddressCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _NoAddressCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color: AppColors.primary,
              style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_outlined,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Add a delivery address',
                  style:
                      AppTextStyles.bodyBold(color: AppColors.primary)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Shared components ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h4()),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: AppTextStyles.captionBold(
                    color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    selected ? AppColors.primary : AppColors.text2,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyBold(
                      color: selected
                          ? AppColors.text1
                          : AppColors.text2)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SumRow(this.label, this.value, {this.valueColor});

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
