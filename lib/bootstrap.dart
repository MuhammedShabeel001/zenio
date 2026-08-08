import 'dart:async';
import 'dart:developer';

import 'package:app/app/app.dart';
import 'package:app/shared/shared.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    log('Provider $provider was initialized with $value');
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    log('Provider $provider was disposed');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    log('Provider $provider updated from $previousValue to $newValue');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    log('Provider $provider threw $error at $stackTrace');
  }
}

Future<void> bootstrap(FutureOr<App> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
    // Enable on setting up of firebase project
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    log(exception.toString(), stackTrace: stackTrace);
    // Enable on setting up of firebase project
    // FirebaseCrashlytics.instance.recordError(exception, stackTrace);
    return true;
  };
  final app = await builder();
  // Add cross-flavor configuration here
  runApp(
    ProviderScope(
      observers: [MyObserver()],
      overrides: [
        envProvider.overrideWithValue(app.environment),
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: app.environment.SERVER_URL)),
        ),
      ],
      child: app,
    ),
  );
}
