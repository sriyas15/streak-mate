import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// dark_theme.dart
/// ThemeData for the main dark/gamified app screens (post-onboarding).
/// Applied via MaterialApp theme switching once the user completes onboarding.
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.dark(
      primary: AppColors.flameOrange,
      secondary: AppColors.xpGold,
      surface: AppColors.darkSurface,
      background: AppColors.darkBg,
      error: AppColors.danger,
    ),
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkBorder,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.flameOrange,
      unselectedItemColor: AppColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}