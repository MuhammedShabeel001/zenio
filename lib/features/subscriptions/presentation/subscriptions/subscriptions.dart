import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/subscriptions/presentation/subscriptions/subscriptions_mobile.dart';
import 'package:zenio/features/subscriptions/presentation/subscriptions/subscriptions_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'subscriptions_mobile.dart';
export 'subscriptions_web.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: ResponsiveWidget(
        smallScreen: SubscriptionsScreenMobile(),
        largeScreen: SubscriptionsScreenWeb(),
      ),
    );
  }
}
