import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/step_indicator.dart';

/// welcome_screen.dart
/// Onboarding step 1/4. Pure presentational — no backend call (the
/// backend's onboardingStep starts at 1 by default, advancing only once
/// the user submits a goal on the next screen).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1B2E),
      body: Stack(
        children: [
          const Positioned.fill(child: JourneyPathIllustration()),
          // Dark gradient overlay at bottom so text stays legible over art
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: StepIndicator(current: 1, total: 4, darkText: false),
                  ),
                  const Spacer(),
                  const Text(
                    'Every day is\na new step.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Small habits today, extraordinary life tomorrow.',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _PillTag(emoji: '🌱', label: 'Build Habits'),
                      SizedBox(width: 10),
                      _PillTag(emoji: '🔥', label: 'Keep Streaks'),
                      SizedBox(width: 10),
                      _PillTag(emoji: '⭐', label: 'Become Better'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Start My Journey',
                    onPressed: () => context.go(RouteNames.onboardingGoal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}
