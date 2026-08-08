import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/presentation/wallet/wallet_mobile.dart';
import 'package:zenio/features/wallet/presentation/wallet/wallet_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'wallet_mobile.dart';
export 'wallet_web.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ResponsiveWidget(
        smallScreen: WalletScreenMobile(onTabSelected: onTabSelected),
        largeScreen: WalletScreenWeb(onTabSelected: onTabSelected),
      ),
    );
  }
}
