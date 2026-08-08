import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/analytics/presentation/analytics/analytics_mobile.dart';
import 'package:zenio/features/analytics/presentation/analytics/analytics_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'analytics_mobile.dart';
export 'analytics_web.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ResponsiveWidget(
        smallScreen: AnalyticsScreenMobile(onTabSelected: onTabSelected),
        largeScreen: AnalyticsScreenWeb(onTabSelected: onTabSelected),
      ),
    );
  }
}
