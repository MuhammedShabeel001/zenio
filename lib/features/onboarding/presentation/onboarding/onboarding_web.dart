import 'package:flutter/material.dart';
import 'package:zenio/features/onboarding/presentation/onboarding/onboarding_mobile.dart';

class OnboardingScreenWeb extends StatelessWidget {
  const OnboardingScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const OnboardingScreenMobile(),
        ),
      ),
    );
  }
}
