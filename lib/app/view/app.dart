import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:upgrader/upgrader.dart';
import 'package:zenio/env.dart';
import 'package:zenio/shared/shared.dart';

class App extends ConsumerWidget {
  App({required this.environment, super.key});
  final IEnvironment environment;
  // Add upgrader URL
  static const appcastURL = '';
  final upgrader = Upgrader(
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
      oniOS: () => UpgraderAppcastStore(appcastURL: appcastURL),
    ),
    debugLogging: kDebugMode,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    // Opens local storage as early as possible; the splash waits for it.
    ref.watch(sqlitePrefsProvider);
    return MaterialApp.router(
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
      title: 'Zenio',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeNotifierProvider),
      scrollBehavior: const CustomScrollBehavior(),
      builder: (context, child) {
        return PrivacyShield(
          child: UpgradeAlert(
            navigatorKey: appRouter.router.routerDelegate.navigatorKey,
            child: child,
          ),
        );
      },
    );
  }
}
