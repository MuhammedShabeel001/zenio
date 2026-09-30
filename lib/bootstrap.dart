import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/app/app.dart';
import 'package:zenio/shared/shared.dart';

/// Debug-only provider logging. It prints provider names and value types,
/// never the values themselves, so no personal or vault data reaches a log.
class MyObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    log('Provider ${_name(provider)} initialized (${value.runtimeType})');
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    log('Provider ${_name(provider)} disposed');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    log('Provider ${_name(provider)} failed',
        error: error, stackTrace: stackTrace,);
  }

  static String _name(ProviderBase<Object?> provider) =>
      provider.name ?? provider.runtimeType.toString();
}

Future<void> bootstrap(FutureOr<App> Function() builder) async {
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    log(details.exceptionAsString(), stackTrace: details.stack);
    // Enable on setting up of firebase project
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    log(exception.toString(), stackTrace: stackTrace);
    // Enable on setting up of firebase project
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    log('Failed to initialize NotificationService: $e');
  }

  final app = await builder();
  // Add cross-flavor configuration here
  runApp(
    ProviderScope(
      observers: [if (kDebugMode) MyObserver()],
      overrides: [
        envProvider.overrideWithValue(app.environment),
        dioProvider.overrideWithValue(
          Dio(
            BaseOptions(
              baseUrl: app.environment.SERVER_URL,
              connectTimeout: app.environment.CONNECT_TIMEOUT,
              sendTimeout: app.environment.CONNECT_TIMEOUT,
              receiveTimeout: app.environment.RECEIVE_TIMEOUT,
            ),
          ),
        ),
      ],
      child: app,
    ),
  );
}
