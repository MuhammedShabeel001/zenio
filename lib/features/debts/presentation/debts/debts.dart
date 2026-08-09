import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/debts/presentation/debts/debts_mobile.dart';
import 'package:zenio/features/debts/presentation/debts/debts_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'debts_mobile.dart';
export 'debts_web.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: ResponsiveWidget(
        smallScreen: DebtsScreenMobile(),
        largeScreen: DebtsScreenWeb(),
      ),
    );
  }
}
