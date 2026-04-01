import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/app_models.dart';
import '../../providers/profile_providers.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(
        title: 'Saved Addresses',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showAddressSheet(context, ref, null),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: Text('Add',
                  style:
                      AppTextStyles.captionBold(color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: addressesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (addresses) => addresses.isEmpty
            ? EmptyState(
                iconWidget: Image.asset(
                  'assets/icons/location.png',
                  width: 72,
                  height: 72,
                ),
                title: 'No saved addresses',
                subtitle: 'Add a delivery address to get started',
                action: ElevatedButton(
                  onPressed: () => _showAddressSheet(context, ref, null),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 44)),
                  child: const Text('Add Address'),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _AddressCard(
                  address: addresses[i],
                  onEdit: () =>
                      _showAddressSheet(context, ref, addresses[i]),
                  onDelete: () =>
                      _confirmDelete(context, ref, addresses[i].id),
                  onSetDefault: () => ref
                      .read(addressesProvider.notifier)
                      .setDefault(addresses[i].id),
                ),
              ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text('Delete Address', style: AppTextStyles.h4()),
        content:
            Text('Remove this address?', style: AppTextStyles.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(addressesProvider.notifier).delete(id);
    }
  }
}

void _showAddressSheet(
    BuildContext context, WidgetRef ref, AddressModel? existing) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _AddressSheet(existing: existing, ref: ref),
  );
}

// ─── Address Card ─────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color:
              address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppColors.primarySoft
                        : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    address.label,
                    style: AppTextStyles.captionBold(
                        color: address.isDefault
                            ? AppColors.primary
                            : AppColors.text2),
                  ),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                const Spacer(),
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.text2),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Name & phone
            if (address.fullName.isNotEmpty)
              Text(address.fullName,
                  style: AppTextStyles.bodyBold()),
            if (address.phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(address.phone,
                  style: AppTextStyles.caption(
                      color: AppColors.text2)),
            ],
            const SizedBox(height: 4),

            // Address lines
            Text(address.fullAddress,
                style: AppTextStyles.body()),
            if (address.landmark != null &&
                address.landmark!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Landmark: ${address.landmark}',
                  style: AppTextStyles.caption(
                      color: AppColors.text2)),
            ],

            if (!address.isDefault) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onSetDefault,
                child: Text('Set as default',
                    style: AppTextStyles.captionBold(
                        color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Address Bottom Sheet ─────────────────────────────────────────────────────
class _AddressSheet extends StatefulWidget {
  final AddressModel? existing;
  final WidgetRef ref;

  const _AddressSheet({this.existing, required this.ref});

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _line1Ctrl;
  late final TextEditingController _line2Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _landmarkCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _labelCtrl = TextEditingController(text: a?.label ?? 'Home');
    _fullNameCtrl = TextEditingController(text: a?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _line1Ctrl = TextEditingController(text: a?.line1 ?? '');
    _line2Ctrl = TextEditingController(text: a?.line2 ?? '');
    _cityCtrl = TextEditingController(text: a?.city ?? '');
    _stateCtrl = TextEditingController(text: a?.state ?? '');
    _pincodeCtrl = TextEditingController(text: a?.pincode ?? '');
    _landmarkCtrl = TextEditingController(text: a?.landmark ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _labelCtrl, _fullNameCtrl, _phoneCtrl, _line1Ctrl,
      _line2Ctrl, _cityCtrl, _stateCtrl, _pincodeCtrl, _landmarkCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final address = AddressModel(
        id: widget.existing?.id ?? '',
        label: _labelCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        line1: _line1Ctrl.text.trim(),
        line2: _line2Ctrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        isDefault: widget.existing?.isDefault ?? false,
      );
      if (widget.existing != null) {
        await widget.ref.read(addressesProvider.notifier).update(address);
      } else {
        await widget.ref.read(addressesProvider.notifier).add(address);
      }
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
        child: SingleChildScrollView(
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
              Text(
                widget.existing != null ? 'Edit Address' : 'Add Address',
                style: AppTextStyles.h4(),
              ),
              const SizedBox(height: 20),

              // Label chips
              Text('Label',
                  style: AppTextStyles.captionBold(
                      color: AppColors.text2)),
              const SizedBox(height: 8),
              Row(
                children: ['Home', 'Work', 'Other'].map((l) {
                  final sel = _labelCtrl.text == l;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _labelCtrl.text = l),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(l,
                            style: AppTextStyles.captionBold(
                                color: sel
                                    ? Colors.white
                                    : AppColors.text2)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _F(ctrl: _fullNameCtrl, label: 'Full Name',
                  hint: 'Recipient name', required: true),
              const SizedBox(height: 12),
              _F(ctrl: _phoneCtrl, label: 'Phone',
                  hint: '10-digit mobile number',
                  keyboard: TextInputType.phone, required: true),
              const SizedBox(height: 12),
              _F(ctrl: _line1Ctrl, label: 'Address Line 1',
                  hint: 'House no, Street, Area', required: true),
              const SizedBox(height: 12),
              _F(ctrl: _line2Ctrl, label: 'Address Line 2 (optional)',
                  hint: 'Apartment, Colony'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _F(ctrl: _cityCtrl, label: 'City',
                        hint: 'Patna', required: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _F(ctrl: _stateCtrl, label: 'State',
                        hint: 'Bihar', required: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _F(
                      ctrl: _pincodeCtrl,
                      label: 'Pincode',
                      hint: '800001',
                      keyboard: TextInputType.number,
                      required: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                          return '6-digit pincode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _F(ctrl: _landmarkCtrl,
                        label: 'Landmark (optional)',
                        hint: 'Near City Mall'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: widget.existing != null
                    ? 'Update Address'
                    : 'Save Address',
                isLoading: _loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Field helper ─────────────────────────────────────────────────────────────
class _F extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboard;
  final bool required;
  final String? Function(String?)? validator;

  const _F({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.required = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.captionBold(color: AppColors.text2)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
          validator: validator ??
              (required
                  ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
                  : null),
        ),
      ],
    );
  }
}
