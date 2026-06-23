import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/step_indicator.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1B2E),
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg1.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradient Overlay (Legibility)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.2), // Light top for the black text
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Main UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // --- TOP SECTION ---
                  const Align(
                    alignment: Alignment.topLeft,
                    child: StepIndicator(current: 1, total: 4, darkText: true),
                  ),
                  const SizedBox(height: 40), // Spacing from indicator
                  
                  // Black and Gold Title
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Every day is a \n',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.85), // Black
                            height: 1.1,
                          ),
                        ),
                        const TextSpan(
                          text: 'new step.',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB8860B), // Deep Gold
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Small Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Small habits today, extraordinary life tomorrow.',
                      style: TextStyle(
                        fontSize: 15, 
                        color: Colors.black.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // THIS SPACER pushes everything below it to the bottom
                  const Spacer(),

                  // --- BOTTOM SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _PillTag(emoji: '🌱', label: 'Build Habits'),
                      SizedBox(width: 15),
                      _PillTag(emoji: '🔥', label: 'Keep Streaks'),
                      SizedBox(width: 15),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11, 
            color: Colors.white, 
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }
}