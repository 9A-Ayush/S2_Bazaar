import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _lineWidth;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlay);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)),
    );
    _contentOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut),
    );
    _taglineSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );
    _lineWidth = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _contentCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: 60, left: -80,
            child: _Circle(size: 280, color: AppColors.primarySoft, opacity: 0.5),
          ),
          Positioned(
            bottom: 100, right: -60,
            child: _Circle(size: 220, color: AppColors.primarySoft, opacity: 0.35),
          ),
          Positioned(
            top: -50, right: 80,
            child: _Circle(size: 180, color: AppColors.primarySoft, opacity: 0.3),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value.clamp(0, 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'S2',
                                style: AppTextStyles.display(color: Colors.white)
                                    .copyWith(fontSize: 30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Bazaar',
                            style: AppTextStyles.display(color: AppColors.text1)
                                .copyWith(fontSize: 42),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tagline & accent line
                AnimatedBuilder(
                  animation: _contentCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _contentOpacity.value.clamp(0, 1),
                    child: Column(
                      children: [
                        SlideTransition(
                          position: _taglineSlide,
                          child: Text(
                            'Quality bhi, bachat bhi',
                            style: AppTextStyles.bodyLarge(color: AppColors.text2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedBuilder(
                          animation: _lineWidth,
                          builder: (_, __) => Container(
                            width: 48 * _lineWidth.value,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Your neighbourhood superstore',
                          style: AppTextStyles.caption(color: AppColors.text3),
                        ),
                        const SizedBox(height: 24),
                        // Loading dots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dot(color: AppColors.primary, size: 8),
                            const SizedBox(width: 8),
                            _Dot(color: const Color(0xFFFFCDD2), size: 6),
                            const SizedBox(width: 8),
                            _Dot(color: const Color(0xFFFFCDD2), size: 6),
                          ],
                        ),
                      ],
                    ),
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

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Circle({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
