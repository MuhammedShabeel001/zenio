import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform protections for sensitive screens and copied secrets.
///
/// Backed by the `com.aurea.zenio/security` channel in `MainActivity.kt` and
/// `AppDelegate.swift`. Falls back to plain Dart behaviour where the channel
/// is unavailable (tests, desktop, web).
class SecurePlatform {
  SecurePlatform._();

  static const MethodChannel _channel =
      MethodChannel('com.aurea.zenio/security');

  /// How long a copied secret stays on the clipboard.
  static const Duration clipboardLifetime = Duration(seconds: 60);

  static int _secureScreenHolders = 0;
  static Timer? _fallbackClearTimer;

  /// True while a sensitive screen is open. The app-wide privacy shield
  /// covers everything while this is true and the app is not in front.
  static final ValueNotifier<bool> sensitiveScreenOpen = ValueNotifier(false);

  /// True from the moment a sensitive screen is locked away until it has
  /// closed, so it cannot flash while its closing animation plays.
  static final ValueNotifier<bool> coverUntilClosed = ValueNotifier(false);

  /// Keeps the window out of screenshots and the Android Recents preview
  /// until every caller has called [releaseSecureScreen].
  static Future<void> holdSecureScreen() async {
    _secureScreenHolders++;
    sensitiveScreenOpen.value = true;
    if (_secureScreenHolders == 1) await _setSecureScreen(true);
  }

  static Future<void> releaseSecureScreen() async {
    if (_secureScreenHolders == 0) return;
    _secureScreenHolders--;
    if (_secureScreenHolders == 0) {
      sensitiveScreenOpen.value = false;
      coverUntilClosed.value = false;
      await _setSecureScreen(false);
    }
  }

  /// Keeps the privacy shield up until the sensitive screens have closed.
  static void coverWhileClosing() {
    if (_secureScreenHolders > 0) coverUntilClosed.value = true;
  }

  static Future<void> _setSecureScreen(bool enabled) async {
    try {
      await _channel
          .invokeMethod<void>('setSecureScreen', {'enabled': enabled});
    } on MissingPluginException {
      // Not available on this platform.
    } on PlatformException {
      // Best effort; never block the screen on it.
    }
  }

  /// Copies [text] and removes it from the clipboard after
  /// [clipboardLifetime], as long as nothing else was copied since.
  static Future<void> copySensitive(String text) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        await _channel.invokeMethod<void>('copySensitive', {
          'text': text,
          'clearAfterSeconds': clipboardLifetime.inSeconds,
        });
        return;
      } on MissingPluginException {
        // Fall through to the portable version.
      } on PlatformException {
        // Fall through to the portable version.
      }
    }

    await Clipboard.setData(ClipboardData(text: text));
    _fallbackClearTimer?.cancel();
    _fallbackClearTimer = Timer(clipboardLifetime, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}
