import 'package:flutter/material.dart';
import 'package:zenio/features/onboarding/presentation/onboarding/onboarding_mobile.dart';
import 'package:zenio/features/onboarding/presentation/onboarding/onboarding_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'onboarding/onboarding_mobile.dart';
export 'onboarding/onboarding_web.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveWidget(
      smallScreen: OnboardingScreenMobile(),
      largeScreen: OnboardingScreenWeb(),
    );
  }
}
