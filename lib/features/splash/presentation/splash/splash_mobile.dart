import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/features/splash/presentation/splash/splash_startup.dart';
import 'package:zenio/features/splash/presentation/widgets/animated_zenio_logo.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class SplashScreenMobile extends ConsumerStatefulWidget {
  const SplashScreenMobile({super.key});

  @override
  ConsumerState<SplashScreenMobile> createState() => _SplashScreenMobileState();
}

class _SplashScreenMobileState extends ConsumerState<SplashScreenMobile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _bottomCardSlide;
  late final Animation<double> _bottomCardFade;
  late final Animation<double> _subtitleFade;

  Timer? _navigationTimer;
  bool _hasNavigated = false;
  bool _startupFailed = false;

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

    _navigationTimer =
        Timer(
      // Just after the 1.7s logo animation; storage is awaited as well.
      const Duration(milliseconds: 1800),
      _navigateToNext,
    );
  }

  Future<void> _navigateToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

    final String route;
    try {
      route = await resolveStartupRoute(ref);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasNavigated = false;
        _startupFailed = true;
      });
      return;
    }

    if (!mounted) return;
    context.goNamed(route);
  }

  void _retryStartup() {
    retryStartup(ref);
    setState(() => _startupFailed = false);
    _navigateToNext();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: GestureDetector(
        // After a failed start, a tap anywhere tries again, like the button.
        onTap: _startupFailed ? _retryStartup : _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: AppColors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Main content with cinema animated logo
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedZenioLogo(
                        animation: _controller,
                      ),
                    ),
                  ),
                  // Space placeholder for bottom card so center logo stays naturally centered
                  SizedBox(height: 120 + bottomInset),
                ],
              ),

              // Bottom rounded white branding card
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _bottomCardSlide,
                  child: FadeTransition(
                    opacity: _bottomCardFade,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: 36,
                        bottom: bottomInset > 0 ? bottomInset + 20 : 36,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Assets.images.appFullLogo.svg(
                            height: 28,
                          ),
                          const SizedBox(height: 8),
                          if (_startupFailed) ...[
                            Text(
                              "Zenio couldn't open your data.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ZenioColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: _retryStartup,
                              child: const Text('Try again'),
                            ),
                          ] else
                            FadeTransition(
                              opacity: _subtitleFade,
                              child: Text(
                                'by auren',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: ZenioColors.textSecondary,
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
    );
  }
}
