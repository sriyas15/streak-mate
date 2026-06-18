import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';

/// app.dart
/// Root widget. Theme here covers the light/onboarding surfaces; the
/// dark gamified theme for the main app is applied separately once
/// Home/Habits/etc. are built (see core/theme/dark_theme.dart placeholder).
class StreakMateApp extends ConsumerWidget {
  const StreakMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StreakMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.sproutGreen,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter', // swap for your chosen font in pubspec.yaml
      ),
      routerConfig: router,
    );
  }
}