import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/split/presentation/split/split_mobile.dart';
import 'package:zenio/features/split/presentation/split/split_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'split_mobile.dart';
export 'split_web.dart';

class SplitScreen extends ConsumerWidget {
  const SplitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: ResponsiveWidget(
        smallScreen: SplitScreenMobile(),
        largeScreen: SplitScreenWeb(),
      ),
    );
  }
}
