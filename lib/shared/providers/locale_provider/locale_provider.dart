import 'package:app/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    listenSelf((previous, next) {
      ref
          .read(sharedPrefsProvider)
          .value
          ?.setString('locale', next.languageCode);
    });
    return Locale(
      ref.watch(sharedPrefsProvider).value?.getString('locale') ?? 'en',
    );
  }
}
