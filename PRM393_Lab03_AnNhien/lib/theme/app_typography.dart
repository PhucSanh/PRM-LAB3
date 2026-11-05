import 'package:flutter/material.dart';

/// Reference-led typography. Saved and system text scaling still apply.
abstract final class AppTypography {
  static const fontFamily = 'BeVietnamPro';

  // Intro readability refinement: sturdier serif, tighter tracking, clear copy.
  // Keep this local to the introduction; do not inflate every app text role.
  static const welcomeWordmark = TextStyle(
      fontFamily: 'NotoSerif',
      fontSize: 38,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: 1.5);
  static const welcomeTagline = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: .5);
  static const welcomeBody = TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.5);
  static const welcomeAction = TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3);

  static const elderly = TextTheme(
    displayLarge:
        TextStyle(fontSize: 38, fontWeight: FontWeight.w600, height: 1.2),
    displayMedium:
        TextStyle(fontSize: 36, fontWeight: FontWeight.w600, height: 1.2),
    displaySmall:
        TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.2),
    headlineLarge:
        TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
    headlineMedium:
        TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.25),
    headlineSmall:
        TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.25),
    titleLarge:
        TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
    titleMedium:
        TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
    bodyLarge:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
    labelLarge:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
    labelMedium:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
    labelSmall:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
  );
  static const caregiver = TextTheme(
    displayLarge:
        TextStyle(fontSize: 36, fontWeight: FontWeight.w600, height: 1.2),
    displayMedium:
        TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.2),
    displaySmall:
        TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
    headlineLarge:
        TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.2),
    headlineMedium:
        TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.25),
    headlineSmall:
        TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
    titleLarge:
        TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
    titleMedium:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
    bodyLarge:
        TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
    labelLarge:
        TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
    labelMedium:
        TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
    labelSmall:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
  );
}
