import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        emoji: '🗺️',
        label: 'Journey',
        subtitle: 'Your levelling path — coming soon',
      );
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        emoji: '👥',
        label: 'Friends',
        subtitle: 'Challenges & leaderboard — coming soon',
      );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
        emoji: '👤',
        label: 'Profile',
        subtitle: 'Your stats & settings — coming soon',
      );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(
      {required this.emoji, required this.label, required this.subtitle});
  final String emoji;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
