import 'package:app/env.dart';
import 'package:app/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:upgrader/upgrader.dart';

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
    debugLogging: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    // This is to load initial country settings, sharedPrefs
    ref
      ..watch(ipConfigProvider)
      ..watch(sharedPrefsProvider);
    return MaterialApp.router(
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
      title: 'App',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeNotifierProvider),
      scrollBehavior: const CustomScrollBehavior(),
      builder: (context, child) {
        // You can wrap Internet connection alert here
        return NoInternetAlert(
          navigatorKey: appRouter.router.routerDelegate.navigatorKey,
          child: UpgradeAlert(
            navigatorKey: appRouter.router.routerDelegate.navigatorKey,
            child: child,
          ),
        );
      },
    );
  }
}
