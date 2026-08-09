import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/vault/presentation/vault/vault_mobile.dart';
import 'package:zenio/features/vault/presentation/vault/vault_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'vault_mobile.dart';
export 'vault_web.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: ResponsiveWidget(
        smallScreen: VaultScreenMobile(),
        largeScreen: VaultScreenWeb(),
      ),
    );
  }
}
