import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../providers/location_provider.dart';

class OutOfServiceScreen extends ConsumerStatefulWidget {
  const OutOfServiceScreen({super.key});

  @override
  ConsumerState<OutOfServiceScreen> createState() => _OutOfServiceScreenState();
}

class _OutOfServiceScreenState extends ConsumerState<OutOfServiceScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    await ref.read(locationProvider.notifier).checkLocation();
    if (!mounted) return;
    setState(() => _checking = false);
    final status = ref.read(locationProvider).status;
    if (status == LocationStatus.inRange) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: Column(
            children: [
              const Spacer(),

              // Illustration
              Image.asset(
                'assets/icons/location.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 32),

              Text(
                AppLocalizations.of(context)!.notAvailableTitle,
                style: AppTextStyles.h1(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.notAvailableSubtitle,
                style: AppTextStyles.body(color: AppColors.text2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Info chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/location.png', width: 18, height: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.gopalganjRadius,
                      style: AppTextStyles.captionBold(color: AppColors.text2),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Retry CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checking ? null : _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                  child: _checking
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.tryAgain, style: AppTextStyles.bodyBold(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.movedLocation,
                style: AppTextStyles.caption(color: AppColors.text3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
