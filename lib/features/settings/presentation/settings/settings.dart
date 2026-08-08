import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/presentation/settings/settings_mobile.dart';
import 'package:zenio/features/settings/presentation/settings/settings_web.dart';
import 'package:zenio/shared/widgets/responsive.dart';

export 'settings_mobile.dart';
export 'settings_web.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ResponsiveWidget(
        smallScreen: SettingsScreenMobile(onTabSelected: onTabSelected),
        largeScreen: SettingsScreenWeb(onTabSelected: onTabSelected),
      ),
    );
  }
}
