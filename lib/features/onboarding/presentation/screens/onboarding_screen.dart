import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../providers/location_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      imagePath: 'assets/images/ob1Img.png',
      bgColor: Color(0xFFFFEBEE),
      badgeColor: Color(0xFFFFF5F5),
      badgeTextColor: AppColors.primary,
      step: 'Step 1 of 2',
      title: 'Fresh Groceries\n& Essentials',
      subtitle:
          'Order fresh fruits, vegetables, dairy & daily essentials — delivered to your door.',
    ),
    _OnboardingData(
      imagePath: 'assets/images/ob2Img.png',
      bgColor: Color(0xFFEDE7F6),
      badgeColor: Color(0xFFF3E5F5),
      badgeTextColor: Color(0xFF6A1B9A),
      step: 'Step 2 of 2',
      title: 'Clothing, Sarees\n& More',
      subtitle:
          'Explore trending sarees, ethnic wear, western outfits and everyday essentials.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Request permissions + start GPS check silently as soon as onboarding loads.
    // By the time user finishes login, the location result is already ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSilent());
  }

  Future<void> _initSilent() async {
    // Request location + notification permissions in parallel
    await [
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();

    // Start GPS check silently — result stored in locationProvider
    if (mounted) {
      ref.read(locationProvider.notifier).checkLocation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.soft,
                ),
                child: Text('Skip',
                    style: AppTextStyles.captionBold(
                        color: AppColors.text2)),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 36, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _pages[_currentPage].badgeColor,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _pages[_currentPage].step,
                      style: AppTextStyles.captionBold(
                          color: _pages[_currentPage].badgeTextColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(_pages[_currentPage].title,
                      style: AppTextStyles.h1(),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(_pages[_currentPage].subtitle,
                      style: AppTextStyles.body(),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppColors.primary,
                      dotColor: const Color(0xFFFFCDD2),
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: _next,
                    trailing: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 18),
                    subtitle: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Image.asset(data.imagePath,
                    fit: BoxFit.contain, width: double.infinity),
              ),
            ),
          ),
          const SizedBox(height: 260),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String imagePath;
  final Color bgColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final String step;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.imagePath,
    required this.bgColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.step,
    required this.title,
    required this.subtitle,
  });
}
