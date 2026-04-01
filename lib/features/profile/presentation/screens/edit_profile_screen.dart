import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  XFile? _pickedImage;
  DateTime? _dob;
  String? _gender;
  bool _loading = false;

  static const _genders = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('other', 'Other'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).valueOrNull;
    // Email: prefer profiles table, fall back to auth user directly
    final authEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _emailCtrl = TextEditingController(
        text: (p?.email != null && p!.email!.isNotEmpty) ? p.email! : authEmail);
    _dob = p?.dateOfBirth;
    _gender = p?.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // On web, camera source falls back to gallery automatically
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileProvider.notifier).update(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            avatarFile: _pickedImage,
            dateOfBirth: _dob,
            gender: _gender,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
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
    final avatarUrl = ref.watch(profileProvider).valueOrNull?.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: S2AppBar(title: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: ClipOval(
                          child: _pickedImage != null
                              ? FutureBuilder<Uint8List>(
                                  future: _pickedImage!.readAsBytes(),
                                  builder: (_, snap) => snap.hasData
                                      ? Image.memory(snap.data!,
                                          fit: BoxFit.cover)
                                      : const SizedBox(),
                                )
                              : (avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                              child: Text('👤',
                                                  style: TextStyle(
                                                      fontSize: 38))))
                                  : const Center(
                                      child: Text('👤',
                                          style: TextStyle(fontSize: 38)))),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to change photo',
                    style:
                        AppTextStyles.caption(color: AppColors.primary)),
              ),
              const SizedBox(height: 28),

              // ── Full Name ────────────────────────────────────────────────
              _Label('Full Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Phone ────────────────────────────────────────────────────
              _Label('Phone Number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // ── Email (read-only from auth) ───────────────────────────────
              _Label('Email'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon:
                      const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixIcon: Tooltip(
                    message: 'Email cannot be changed here',
                    child: const Icon(Icons.lock_outline,
                        size: 16, color: AppColors.text3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Date of Birth ────────────────────────────────────────────
              _Label('Date of Birth'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined,
                          size: 20, color: AppColors.text2),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dob != null
                              ? DateFormat('dd MMM yyyy').format(_dob!)
                              : 'Select date of birth',
                          style: _dob != null
                              ? AppTextStyles.body(color: AppColors.text1)
                              : AppTextStyles.body(color: AppColors.text3),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.text3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Gender ───────────────────────────────────────────────────
              _Label('Gender'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genders.map((g) {
                  final selected = _gender == g.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _gender = g.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        g.$2,
                        style: AppTextStyles.captionBold(
                            color: selected
                                ? Colors.white
                                : AppColors.text2),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Save Changes',
                isLoading: _loading,
                onPressed: _save,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.captionBold(color: AppColors.text2));
}
