import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';

/// The template theme with Zenio's brand colours. Its own seed colour is a
/// violet, which showed up in text cursors, selection handles and default
/// widgets.
final themeProvider = StateProvider<ThemeData>((ref) {
  final base = AppTheme.lightTheme;
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: ZenioColors.primary,
      primary: ZenioColors.primary,
      error: ZenioColors.danger,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ZenioColors.primary,
      selectionColor: ZenioColors.primary.withValues(alpha: 0.3),
      selectionHandleColor: ZenioColors.primary,
    ),
  );
});
