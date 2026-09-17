import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography utility enforcing:
/// - Montserrat for all text fonts
/// - Instrument Sans for all numeric displays (amounts, counters, percentages, card numbers, dates)
class AppFonts {
  AppFonts._();

  /// Default text font family: Montserrat
  static String get textFontFamily => GoogleFonts.montserrat().fontFamily!;

  /// Numeric font family: Instrument Sans
  static String get numericFontFamily =>
      GoogleFonts.instrumentSans().fontFamily!;

  /// Creates a text style using Montserrat (for all regular text)
  static TextStyle text({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.montserrat(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  /// Creates a numeric text style using Instrument Sans (for amounts, balances, numbers, counters)
  static TextStyle numeric({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.instrumentSans(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}

/// Extension on [TextStyle] to quickly apply numeric or text font families
extension TextStyleFontExtension on TextStyle {
  /// Converts this style to use Instrument Sans (for numeric values)
  TextStyle get withNumericFont => GoogleFonts.instrumentSans(textStyle: this);

  /// Converts this style to use Montserrat (for regular text)
  TextStyle get withTextFont => GoogleFonts.montserrat(textStyle: this);
}

/// Reusable widget for rendering numbers and currency using Instrument Sans
class NumericText extends StatelessWidget {
  const NumericText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      style: GoogleFonts.instrumentSans(textStyle: baseStyle),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// Helper function to create an Instrument Sans [TextSpan] for RichText widgets
TextSpan numericTextSpan({
  required String text,
  TextStyle? style,
  List<InlineSpan>? children,
}) {
  return TextSpan(
    text: text,
    style: GoogleFonts.instrumentSans(textStyle: style),
    children: children,
  );
}
