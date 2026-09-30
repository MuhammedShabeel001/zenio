import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/analytics/analytics.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/features/settings/settings.dart';
import 'package:zenio/features/subscriptions/presentation/subscriptions/subscriptions_mobile.dart';
import 'package:zenio/features/wallet/wallet.dart';
import 'package:zenio/shared/shared.dart';

export 'home_mobile.dart';
export 'home_web.dart';

/// The main tab shell: Home, Wallet, Analytics and Settings.
///
/// Tabs are built the first time they are opened and then kept alive, so
/// switching tabs keeps their scroll position, filters and data. Back on
/// another tab returns to Home before leaving the app.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _homeTab = 0;
  static const int _tabCount = 4;

  int _selectedTabIndex = _homeTab;
  final Set<int> _openedTabs = {_homeTab};
  StreamSubscription<String>? _reminderTaps;

  /// A quick fade-in of the newly selected tab.
  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    duration: ZenioMotion.fast,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    final notifications = ref.read(notificationServiceProvider);
    _reminderTaps = notifications.reminderTaps.listen(_openSubscription);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launchedFrom = notifications.takeLaunchReminder();
      if (launchedFrom != null) _openSubscription(launchedFrom);
    });
  }

  @override
  void dispose() {
    _reminderTaps?.cancel();
    _tabFade.dispose();
    super.dispose();
  }

  /// Opens Subscriptions with the reminded subscription expanded.
  void _openSubscription(String subscriptionId) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubscriptionsScreenMobile(initialExpandedId: subscriptionId),
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex || index < 0 || index >= _tabCount) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTabIndex = index;
      _openedTabs.add(index);
    });
    _tabFade.forward(from: 0);
  }

  Widget _buildTab(int index) {
    if (!_openedTabs.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => HomeScreenMobile(onTabSelected: _onTabSelected),
      1 => WalletScreenMobile(onTabSelected: _onTabSelected),
      2 => AnalyticsScreenMobile(onTabSelected: _onTabSelected),
      _ => SettingsScreenMobile(onTabSelected: _onTabSelected),
    };
  }

  @override
  Widget build(BuildContext context) {
    final shell = Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            // Starts from partly visible so the switch feels instant.
            opacity: _tabFade.drive(
              Tween<double>(begin: 0.4, end: 1)
                  .chain(CurveTween(curve: ZenioMotion.standardCurve)),
            ),
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [for (var i = 0; i < _tabCount; i++) _buildTab(i)],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CustomNavigationBar(
            selectedIndex: _selectedTabIndex,
            onTabSelected: _onTabSelected,
          ),
        ),
      ],
    );

    return PopScope(
      canPop: _selectedTabIndex == _homeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onTabSelected(_homeTab);
      },
      child: Scaffold(
        body: ResponsiveWidget(
          smallScreen: shell,
          largeScreen: _PhoneFrame(child: shell),
        ),
      ),
    );
  }
}

/// Large screens show the phone layout in a frame (iPad and web layouts are
/// a separate product decision).
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121212),
      child: Center(
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
          child: child,
        ),
      ),
    );
  }
}
