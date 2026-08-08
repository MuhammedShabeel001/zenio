import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';

final themeProvider = StateProvider<ThemeData>((ref) => AppTheme.lightTheme);
