import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/transactions/presentation/transactions/transactions_mobile.dart';
import 'package:zenio/features/transactions/presentation/transactions/transactions_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'transactions_mobile.dart';
export 'transactions_web.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: ResponsiveWidget(
        smallScreen: TransactionsScreenMobile(),
        largeScreen: TransactionsScreenWeb(),
      ),
    );
  }
}
