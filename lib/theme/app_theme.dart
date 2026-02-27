import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Mongol Empire history app.
/// Dark-mode, cinematic, gamified palette.
class AppTheme {
  AppTheme._();

  // ── Colour tokens ──────────────────────────────────────────────
  static const Color background = Color(0xFF0B1220);
  static const Color surface = Color(0xFF111B2E);
  static const Color surfaceLight = Color(0xFF1A2740);
  static const Color accentGold = Color(0xFFF4C84A);
  static const Color crimson = Color(0xFFE04B5A);
  static const Color textPrimary = Color(0xFFEAF0FF);
  static const Color textSecondary = Color(0xFFA9B3C9);
  static const Color divider = Color(0xFF1E2D45);
  static const Color cardBorder = Color(0xFF1E2D45);
  static const Color xpGreen = Color(0xFF4ADE80);
  static const Color streakOrange = Color(0xFFFF9F43);

  // ── Radius tokens ──────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 22;
  static const double radiusFull = 100;

  // ── Spacing tokens ─────────────────────────────────────────────
  static const double pagePadding = 16;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;

  // ── Typography ─────────────────────────────────────────────────
  static TextStyle h2 = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle sectionTitle = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle captionBold = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle button = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: background,
  );

  static TextStyle chip = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // ── ThemeData ──────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accentGold,
          secondary: crimson,
          onPrimary: background,
          onSurface: textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        splashFactory: InkSparkle.splashFactory,
      );
}
