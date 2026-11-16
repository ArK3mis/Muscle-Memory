import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors, sizes and text styles for the pixel look.
class PX {
  PX._();

  static const Color ink = Color(0xFF1B1B2F);
  static const Color paper = Color(0xFFFFFBEF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lime = Color(0xFFB6F23A);
  static const Color blue = Color(0xFF3D6BFF);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color pink = Color(0xFFFF6FB1);
  static const Color yellow = Color(0xFFFFD93D);
  static const Color mint = Color(0xFF9CF0D0);
  static const Color sky = Color(0xFFBFE3FF);
  static const Color grey = Color(0xFF6B6B80);
  static const Color green = Color(0xFF4CD964);
  static const Color red = Color(0xFFFF4D4D);

  static const double border = 3;
  static const double shadow = 4;

  /// Pixel font, for titles and buttons only.
  static TextStyle title(double size, {Color color = ink}) =>
      GoogleFonts.pressStart2p(fontSize: size, color: color, height: 1.4);

  /// Clean font for everything you have to read.
  static TextStyle body(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.dmSans(fontSize: size, color: color, fontWeight: weight);

  static Color regionColor(String region) {
    switch (region) {
      case 'Upper':
        return blue;
      case 'Lower':
        return orange;
      default:
        return pink;
    }
  }
}

ThemeData buildPixelTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PX.paper,
    colorScheme: ColorScheme.fromSeed(seedColor: PX.blue),
    splashFactory: NoSplash.splashFactory,
  );
  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme)
        .apply(bodyColor: PX.ink, displayColor: PX.ink),
  );
}
