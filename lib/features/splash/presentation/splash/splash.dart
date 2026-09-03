import 'package:flutter/material.dart';
import 'package:zenio/features/splash/presentation/splash/splash_mobile.dart';
import 'package:zenio/features/splash/presentation/splash/splash_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'splash_mobile.dart';
export 'splash_web.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveWidget(
      smallScreen: SplashScreenMobile(),
      largeScreen: SplashScreenWeb(),
    );
  }
}
