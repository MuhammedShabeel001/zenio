import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/features/onboarding/controller/onboarding_controller.dart';
import 'package:zenio/features/onboarding/domain/models/onboarding_page_item.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/router.dart';

class OnboardingScreenMobile extends ConsumerStatefulWidget {
  const OnboardingScreenMobile({super.key});

  @override
  ConsumerState<OnboardingScreenMobile> createState() =>
      _OnboardingScreenMobileState();
}

class _OnboardingScreenMobileState
    extends ConsumerState<OnboardingScreenMobile> {
  final PageController _pageController = PageController();
  final List<OnboardingPageItem> _pages = OnboardingPageItem.pages;
  int _currentIndex = 0;
  bool _isNavigating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPreviousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _onFinishOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.goNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    final isLastPage = _currentIndex == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7F7F8),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            // Animated PageView
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      var page = index.toDouble();
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        page = _pageController.page ?? _currentIndex.toDouble();
                      }

                      final offset = page - index;
                      final absOffset = offset.abs().clamp(0.0, 1.0);

                      // Multi-plane parallax, scale, tilt and fade animations
                      final illustrationScale =
                          (1.0 - (absOffset * 0.32)).clamp(0.68, 1.0);
                      final illustrationOpacity =
                          (1.0 - (absOffset * 1.3)).clamp(0.0, 1.0);
                      final illustrationTranslateX = -offset * 130.0;
                      final illustrationTranslateY = absOffset * 35.0;
                      final illustrationRotation = -offset * 0.08;

                      // Staggered text parallax & slide up/down
                      final titleTranslateX = offset * 180.0;
                      final titleTranslateY = absOffset * 28.0;
                      final titleOpacity =
                          (1.0 - (absOffset * 1.5)).clamp(0.0, 1.0);

                      final subtitleTranslateX = offset * 260.0;
                      final subtitleTranslateY = absOffset * 42.0;
                      final subtitleOpacity =
                          (1.0 - (absOffset * 1.8)).clamp(0.0, 1.0);

                      return Padding(
                        padding: EdgeInsets.only(
                          top: topInset + 16,
                          bottom: 140 + bottomInset,
                          left: 24,
                          right: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),

                            // Center Illustration with responsive scale, counter-parallax and dynamic transition
                            Expanded(
                              flex: 6,
                              child: Center(
                                child: Transform.translate(
                                  offset: Offset(
                                    illustrationTranslateX,
                                    illustrationTranslateY,
                                  ),
                                  child: Transform.rotate(
                                    angle: illustrationRotation,
                                    child: Transform.scale(
                                      scale: illustrationScale,
                                      child: Opacity(
                                        opacity: illustrationOpacity,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 260,
                                            maxHeight: 260,
                                          ),
                                          child: item.image.image(
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Title with animated slide and fade
                            Transform.translate(
                              offset: Offset(
                                titleTranslateX,
                                titleTranslateY,
                              ),
                              child: Opacity(
                                opacity: titleOpacity,
                                child: Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.text(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Subtitle with animated slide and fade
                            Transform.translate(
                              offset: Offset(
                                subtitleTranslateX,
                                subtitleTranslateY,
                              ),
                              child: Opacity(
                                opacity: subtitleOpacity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    item.subtitle,
                                    textAlign: TextAlign.center,
                                    style: AppFonts.text(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF8E8E93),
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Rounded Action Card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F8),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(38),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom: bottomInset > 0 ? bottomInset + 16 : 24,
                ),
                child: Row(
                  children: [
                    // Step indicators: 40x10 active, 20x10 inactive, 3px spacing
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_pages.length, (index) {
                        final isActive = index == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(
                            right: index < _pages.length - 1 ? 3 : 0,
                          ),
                          height: 10,
                          width: isActive ? 40 : 20,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF05B67B)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),

                    // Action Controls: 3px spacing between buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Previous button (60x60, no bg, 3px margin if visible)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.horizontal,
                              child: child,
                            ),
                          ),
                          child: _currentIndex > 0
                              ? Padding(
                                  key: const ValueKey('prev_button_wrapper'),
                                  padding: const EdgeInsets.only(right: 3),
                                  child: _OnboardingButton(
                                    key: const ValueKey(
                                      'onboarding_prev_button',
                                    ),
                                    width: 60,
                                    onTap: _onPreviousPage,
                                    borderColor: const Color(0xFFE5E5EA),
                                    child: Assets.icons.leftArrow.svg(
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF222222),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('prev_empty'),
                                ),
                        ),

                        // Actions for pages 0, 1, 2 vs Final Page
                        if (!isLastPage) ...[
                          // Skip button: 72x60, no background color
                          _OnboardingButton(
                            key: const ValueKey('onboarding_skip_button'),
                            width: 72,
                            onTap: _onFinishOnboarding,
                            borderColor: const Color(0xFFE5E5EA),
                            child: Text(
                              'Skip',
                              style: AppFonts.text(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8E8E93),
                              ),
                            ),
                          ),

                          const SizedBox(width: 3),

                          // Next button: 60x60, green background
                          _OnboardingButton(
                            key: const ValueKey('onboarding_next_button'),
                            width: 60,
                            onTap: _onNextPage,
                            backgroundColor: const Color(0xFF05B67B),
                            child: Assets.icons.rightArrow.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Enter Zenio button: 103x60, green background
                          _OnboardingButton(
                            key: const ValueKey('onboarding_enter_button'),
                            width: 103,
                            onTap: _onFinishOnboarding,
                            backgroundColor: const Color(0xFF05B67B),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Enter ',
                                    style: AppFonts.text(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Zenio',
                                    style: AppFonts.text(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.child,
    required this.onTap,
    super.key,
    this.width,
    this.backgroundColor = Colors.transparent,
    this.borderColor,
  });

  static const double _height = 60;

  final Widget child;
  final VoidCallback onTap;
  final double? width;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: _height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(_height / 2),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.2)
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}
