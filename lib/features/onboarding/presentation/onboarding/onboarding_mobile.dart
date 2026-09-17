import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/features/onboarding/controller/onboarding_controller.dart';
import 'package:zenio/features/onboarding/domain/models/onboarding_page_item.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
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
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPreviousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 360),
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
            // PageView content
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
                  return Padding(
                    padding: EdgeInsets.only(
                      top: topInset + 20,
                      bottom: 150 + bottomInset,
                      left: 28,
                      right: 28,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Center Illustration (responsive scaling)
                        Expanded(
                          flex: 6,
                          child: Center(
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

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppFonts.text(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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

                        const Spacer(),
                      ],
                    ),
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
                  left: 26,
                  right: 26,
                  top: 28,
                  bottom: bottomInset > 0 ? bottomInset + 16 : 28,
                ),
                child: Row(
                  children: [
                    // Step indicators (animated capsules)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_pages.length, (index) {
                        final isActive = index == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(right: 6),
                          height: 7,
                          width: isActive ? 30 : 13,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF05B67B)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),

                    // Action Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back circular button (visible on pages > 0)
                        AnimatedOpacity(
                          opacity: _currentIndex > 0 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: _currentIndex == 0,
                            child: _CircularButton(
                              onTap: _onPreviousPage,
                              borderColor: const Color(0xFFE5E5EA),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),
                        ),

                        if (_currentIndex > 0) const SizedBox(width: 10),

                        // Middle and Forward Actions
                        if (!isLastPage) ...[
                          // Skip button
                          _CircularButton(
                            onTap: _onFinishOnboarding,
                            borderColor: const Color(0xFFE5E5EA),
                            child: Text(
                              'Skip',
                              style: AppFonts.text(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8E8E93),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Next green button
                          _CircularButton(
                            onTap: _onNextPage,
                            backgroundColor: const Color(0xFF05B67B),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ] else ...[
                          // Enter Zenio Pill Button
                          GestureDetector(
                            onTap: _onFinishOnboarding,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF05B67B),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
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

class _CircularButton extends StatelessWidget {
  const _CircularButton({
    required this.child,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.2)
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}
