import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../providers/profile_providers.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(
        title: 'Payments & Wallet',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: Text('Add',
                  style: AppTextStyles.captionBold(color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (methods) => methods.isEmpty
            ? EmptyState(
                emoji: '💳',
                title: 'No payment methods',
                subtitle: 'Add a UPI ID or card for faster checkout',
                action: ElevatedButton(
                  onPressed: () => _showAddSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 44)),
                  child: const Text('Add Method'),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: methods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _PaymentCard(
                  method: methods[i],
                  onDelete: () => _confirmDelete(context, ref, methods[i].id),
                ),
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text('Remove Method', style: AppTextStyles.h4()),
        content: Text('Remove this payment method?', style: AppTextStyles.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Remove',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(paymentMethodsProvider.notifier).delete(id);
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddPaymentSheet(ref: ref),
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────
class _PaymentCard extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onDelete;

  const _PaymentCard({required this.method, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeBg(method.type),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(_typeEmoji(method.type),
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: AppTextStyles.bodyBold()),
                  const SizedBox(height: 2),
                  Text(method.details,
                      style: AppTextStyles.caption(color: AppColors.text2)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(method.type,
                  style: AppTextStyles.label(color: AppColors.text2)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'UPI': return const Color(0xFFE8F5E9);
      case 'Card': return const Color(0xFFE3F2FD);
      default: return AppColors.surface;
    }
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'UPI': return '📱';
      case 'Card': return '💳';
      default: return '🏦';
    }
  }
}

// ─── Add Payment Sheet ────────────────────────────────────────────────────────
class _AddPaymentSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddPaymentSheet({required this.ref});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'UPI';
  final _labelCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final method = PaymentMethodModel(
        id: '',
        type: _type,
        label: _labelCtrl.text.trim(),
        details: _detailsCtrl.text.trim(),
      );
      await widget.ref.read(paymentMethodsProvider.notifier).add(method);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
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
            Text('Add Payment Method', style: AppTextStyles.h4()),
            const SizedBox(height: 20),

            // Type selector
            Text('Type',
                style: AppTextStyles.captionBold(color: AppColors.text2)),
            const SizedBox(height: 8),
            Row(
              children: ['UPI', 'Card', 'NetBanking'].map((t) {
                final selected = _type == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(t,
                          style: AppTextStyles.captionBold(
                              color: selected
                                  ? Colors.white
                                  : AppColors.text2)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Label',
                style: AppTextStyles.captionBold(color: AppColors.text2)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                hintText: _type == 'UPI'
                    ? 'e.g. My PhonePe'
                    : _type == 'Card'
                        ? 'e.g. HDFC Debit'
                        : 'e.g. SBI NetBanking',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            Text(
              _type == 'UPI'
                  ? 'UPI ID'
                  : _type == 'Card'
                      ? 'Last 4 digits'
                      : 'Bank Name',
              style: AppTextStyles.captionBold(color: AppColors.text2),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _detailsCtrl,
              keyboardType: _type == 'Card'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                hintText: _type == 'UPI'
                    ? 'name@upi'
                    : _type == 'Card'
                        ? '1234'
                        : 'State Bank of India',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Save Method',
              isLoading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
