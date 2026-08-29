import 'package:zenio/shared/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/shared/shared.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    listenSelf((previous, next) {
      ref
          .read(sqlitePrefsProvider)
          .value
          ?.setString('locale', next.languageCode);
    });
    return Locale(
      ref.watch(sqlitePrefsProvider).value?.getString('locale') ?? 'en',
    );
  }
}
