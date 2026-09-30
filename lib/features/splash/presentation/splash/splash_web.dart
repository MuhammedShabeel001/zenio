import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/features/splash/presentation/splash/splash_startup.dart';
import 'package:zenio/features/splash/presentation/widgets/animated_zenio_logo.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class SplashScreenWeb extends ConsumerStatefulWidget {
  const SplashScreenWeb({super.key});

  @override
  ConsumerState<SplashScreenWeb> createState() => _SplashScreenWebState();
}

class _SplashScreenWebState extends ConsumerState<SplashScreenWeb>
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
    return GestureDetector(
      // After a failed start, a tap anywhere tries again, like the button.
      onTap: _startupFailed ? _retryStartup : _navigateToNext,
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
      ),
    );
  }
}
