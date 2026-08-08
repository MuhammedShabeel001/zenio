import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/analytics/presentation/analytics/analytics_mobile.dart';

class AnalyticsScreenWeb extends ConsumerStatefulWidget {
  const AnalyticsScreenWeb({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<AnalyticsScreenWeb> createState() => _AnalyticsScreenWebState();
}

class _AnalyticsScreenWebState extends ConsumerState<AnalyticsScreenWeb> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 920),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AnalyticsScreenMobile(onTabSelected: widget.onTabSelected),
        ),
      ),
    );
  }
}
