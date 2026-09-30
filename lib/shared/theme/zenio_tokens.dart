import 'package:flutter/widgets.dart';

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

  /// [danger] for small text on the black headers and dark cards, where
  /// [danger] itself is too dark to read (6.3:1 on #1A1A1A).
  static const Color dangerOnDark = Color(0xFFF87171);

  /// Money coming in (income, "owes you"). Readable on white (5.5:1).
  static const Color income = primaryStrong;

  /// Secondary text on the black screen headers (5.3:1 on black).
  static const Color textOnDarkSecondary = Color(0xFF808080);

  /// Cards and pills on the black screen headers, and their border.
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceDarkBorder = Color(0xFF313131);
}

/// Font sizes by role. New and reworked text uses these instead of one-off
/// sizes; nothing smaller than [caption] is used for text people need to
/// read.
abstract final class ZenioFontSizes {
  /// Captions, secondary details and small labels.
  static const double caption = 12;

  /// Supporting labels next to values.
  static const double label = 13;

  /// Body text.
  static const double body = 14;

  /// List titles and amounts in rows.
  static const double bodyLarge = 16;

  /// Section titles.
  static const double title = 20;

  /// Amounts entered in forms, and the cents of headline amounts.
  static const double amount = 24;

  /// Headline amounts at the top of a screen.
  static const double display = 32;
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

  /// [duration], or none when the system asks for reduced motion. Use it for
  /// every animation that is only there to explain a change.
  static Duration of(BuildContext context, Duration duration) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduce ? Duration.zero : duration;
  }
}
