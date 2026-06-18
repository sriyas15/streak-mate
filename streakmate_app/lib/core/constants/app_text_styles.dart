import 'package:flutter/material.dart';
import 'app_colors.dart';

/// app_text_styles.dart
class AppTextStyles {
  AppTextStyles._();

  // ─── Light theme (onboarding) ───────────────────────────────────────────
  static const TextStyle lightHeadline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.lightTextPrimary,
    height: 1.25,
  );

  static const TextStyle lightSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextSecondary,
    height: 1.4,
  );

  static const TextStyle lightLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextSecondary,
    letterSpacing: 0.4,
  );

  static const TextStyle lightCardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle lightCardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ─── Dark theme (main app) ───────────────────────────────────────────────
  static const TextStyle darkHeadline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle darkBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
  );
}