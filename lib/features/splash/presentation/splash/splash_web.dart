import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/features/splash/presentation/widgets/animated_zenio_logo.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/router.dart';

class SplashScreenWeb extends StatefulWidget {
  const SplashScreenWeb({super.key});

  @override
  State<SplashScreenWeb> createState() => _SplashScreenWebState();
}

class _SplashScreenWebState extends State<SplashScreenWeb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _bottomCardSlide;
  late final Animation<double> _bottomCardFade;
  late final Animation<double> _subtitleFade;

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _bottomCardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _bottomCardFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.82, curve: Curves.easeOut),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 1, curve: Curves.easeOut),
    );

    _controller.forward();

    _navigationTimer = Timer(const Duration(milliseconds: 2600), _navigateToHome);
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();
    context.goNamed(AppRouter.home);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToHome,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AnimatedZenioLogo(
                          animation: _controller,
                        ),
                      ),
                    ),
                    const SizedBox(height: 156),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SlideTransition(
                    position: _bottomCardSlide,
                    child: FadeTransition(
                      opacity: _bottomCardFade,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Assets.images.appFullLogo.svg(
                              height: 28,
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _subtitleFade,
                              child: const Text(
                                'by aureo',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8E8E93),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
