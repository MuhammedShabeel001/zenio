import 'package:flutter/animation.dart';

/// Zenio's colours, taken from the values the screens already use.
///
/// Prefer these over `Color(0x...)` literals so that a change, such as the
/// contrast fix for [textSecondary], applies everywhere at once.
abstract final class ZenioColors {
  /// Brand green: primary buttons, the add button, positive amounts.
  static const Color primary = Color(0xFF10B981);

  /// Darker brand green for text and small elements on light backgrounds,
  /// where [primary] is too light to read (it passes WCAG AA; primary does
  /// not).
  static const Color primaryStrong = Color(0xFF047857);

  static const Color textPrimary = Color(0xFF111111);

  /// Secondary text and icons. Darkened from #8E8E93, which was below the
  /// WCAG AA contrast minimum on white (3.3:1); this is 5.1:1.
  static const Color textSecondary = Color(0xFF6E6E73);

  /// Placeholder text in fields.
  static const Color textPlaceholder = Color(0xFF9E9EA5);

  /// Filled input fields and chips on white.
  static const Color fieldFill = Color(0xFFF2F2F2);

  /// The light sheet under the dark screen headers.
  static const Color sheet = Color(0xFFF7F7F7);

  static const Color border = Color(0xFFD1D1D6);

  /// Deletion, spending and errors.
  static const Color danger = Color(0xFFDD3D34);
}

/// Spacing steps used for padding and gaps.
abstract final class ZenioSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Corner radii.
abstract final class ZenioRadii {
  static const double field = 20;
  static const double card = 24;
  static const double dialog = 28;
  static const double sheet = 30;
  static const double pill = 999;
}

/// Motion: short, consistent durations and curves for all animations.
abstract final class ZenioMotion {
  /// Small state changes: toggles, selection, button feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// Most transitions: expanding, switching content, removing items.
  static const Duration standard = Duration(milliseconds: 250);

  /// Larger movements, such as a card sliding into place.
  static const Duration slow = Duration(milliseconds: 350);

  /// Elements settling into place.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Elements that move within the screen (swipes, reorders).
  static const Curve emphasizedCurve = Curves.fastOutSlowIn;
}
