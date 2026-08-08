import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/analytics/analytics.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/features/settings/settings.dart';
import 'package:zenio/features/wallet/wallet.dart';
import 'package:zenio/shared/shared.dart';

export 'home_mobile.dart';
export 'home_web.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreenMobile(onTabSelected: _onTabSelected),
      WalletScreenMobile(onTabSelected: _onTabSelected),
      AnalyticsScreenMobile(onTabSelected: _onTabSelected),
      SettingsScreenMobile(onTabSelected: _onTabSelected),
    ];

    final webScreens = [
      HomeScreenWeb(onTabSelected: _onTabSelected),
      WalletScreenWeb(onTabSelected: _onTabSelected),
      AnalyticsScreenWeb(onTabSelected: _onTabSelected),
      SettingsScreenWeb(onTabSelected: _onTabSelected),
    ];

    final activeScreen = screens[_selectedTabIndex.clamp(0, screens.length - 1)];
    final activeWebScreen = webScreens[_selectedTabIndex.clamp(0, webScreens.length - 1)];

    return Scaffold(
      body: ResponsiveWidget(
        smallScreen: activeScreen,
        largeScreen: activeWebScreen,
      ),
    );
  }
}
