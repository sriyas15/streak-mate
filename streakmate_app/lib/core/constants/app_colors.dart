import 'package:flutter/material.dart';

/// app_colors.dart
/// Two palettes:
///  - Light/illustrated palette  → used in onboarding (matches uploaded mockups)
///  - Dark/gamified palette      → used in the main app post-onboarding
class AppColors {
  AppColors._();

  // ─── Light / Onboarding palette ─────────────────────────────────────────
  static const Color lightBg = Color(0xFFFBF8F1);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE8E3D8);
  static const Color lightTextPrimary = Color(0xFF1F2B22);
  static const Color lightTextSecondary = Color(0xFF6B7568);

  // Accent greens used on "Continue" buttons / progress in onboarding
  static const Color sproutGreen = Color(0xFF4F8B5C);
  static const Color sproutGreenDark = Color(0xFF3C6E47);

  // Category accent colors (mirrors backend HABIT_TEMPLATES.color)
  static const Color gymRed = Color(0xFFE24B4A);
  static const Color prayerPurple = Color(0xFF7F77DD);
  static const Color studyAmber = Color(0xFFBA7517);
  static const Color dietGreen = Color(0xFF1D9E75);
  static const Color welfareBlue = Color(0xFF185FA5);
  static const Color customGray = Color(0xFF888780);

  // ─── Dark / Gamified palette (main app) ─────────────────────────────────
  static const Color darkBg = Color(0xFF12141C);
  static const Color darkSurface = Color(0xFF1B1F2A);
  static const Color darkSurfaceElevated = Color(0xFF232838);
  static const Color darkBorder = Color(0xFF2E3344);
  static const Color darkTextPrimary = Color(0xFFF4F2EC);
  static const Color darkTextSecondary = Color(0xFFA9ADBB);

  // ── Primary accent — warm gold (replaces old orange throughout the app) ──
  static const Color flameOrange = Color(0xFFE5C07A);      // was 0xFFF2A33D
  static const Color flameOrangeDeep = Color(0xFFE5C07A);  // was 0xFFE8762B
  static const Color xpGold = Color(0xFFE5C07A);           // same warm gold

  // Shared status colors
  static const Color success = Color(0xFF1D9E75);
  static const Color danger = Color(0xFFD85A30);
  static const Color warning = Color(0xFFEF9F27);
  static const Color info = Color(0xFF378ADD);

  /// Returns the brand color associated with a backend habit category.
  static Color forCategory(String category) {
    switch (category) {
      case 'gym':
        return gymRed;
      case 'prayer':
        return prayerPurple;
      case 'study':
        return studyAmber;
      case 'diet':
        return dietGreen;
      case 'welfare':
        return welfareBlue;
      default:
        return customGray;
    }
  }
}