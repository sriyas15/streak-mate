import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'achievements_screen.dart';
import 'habit_reminders_screen.dart';
import 'freeze_days_screen.dart';
import 'settings_screen.dart';
import 'insights_screen.dart';
import '../../../shared/widgets/custom_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      // Removed the top SafeArea wrapper so the background image can reach the absolute top of the screen
      body: CustomScrollView(
        slivers: [

          // ── 1. Unified Hero Section (Background Image + Top Bar + Avatar + Bio) ──
          SliverToBoxAdapter(
            child: _ProfileHeroSection(
              user: user,
              onSettingsTap: () => _push(context, const SettingsScreen()),
              onEditTap: () => _push(context, const EditProfileScreen()),
            ),
          ),

          // ── 2. Separated Level / XP Card (Matches exact UI) ─────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _LevelXpCard(
                level: user?.level ?? 1,
                currentXp: user?.xpPoints ?? 0,
                nextLevelXp: user?.xpToNextLevel ?? 100,
              ),
            ),
          ),

          // ── 3. Stats Row (Kept as requested, moved below Level card) ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _StatTile(
                      emoji: '🔥',
                      value: '${user?.currentStreakDays ?? 0}',
                      label: 'Streak',
                      color: AppColors.flameOrange),
                  const SizedBox(width: 10),
                  _StatTile(
                      emoji: '🏆',
                      value: '${user?.bestStreakDays ?? 0}',
                      label: 'Best',
                      color: AppColors.xpGold),
                  const SizedBox(width: 10),
                  _StatTile(
                      emoji: '❄️',
                      value: '${user?.freezesRemaining ?? 0}',
                      label: 'Freezes',
                      color: AppColors.welfareBlue),
                  const SizedBox(width: 10),
                  _StatTile(
                      emoji: '🎭',
                      value: '${user?.cheatDaysRemaining ?? 0}',
                      label: 'Cheat Days',
                      color: AppColors.prayerPurple),
                ],
              ),
            ),
          ),

          // ── 4. Menu Section ─────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text('',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                      letterSpacing: 0.5)),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.emoji_events_rounded,
                    emoji: '🏆',
                    label: 'Achievements',
                    color: AppColors.xpGold,
                    onTap: () => _push(context, const AchievementsScreen()),
                  ),
                  _MenuRow(
                    icon: Icons.emoji_events_rounded,
                    emoji: '📈',
                    label: 'Insights',
                    color: AppColors.xpGold,
                    onTap: () => _push(context, const InsightsScreen()),
                  ),
                  _divider(),
                  _MenuRow(
                    icon: Icons.notifications_outlined,
                    emoji: '🔔',
                    label: 'Habit Reminders',
                    color: AppColors.flameOrange,
                    onTap: () => _push(context, const HabitRemindersScreen()),
                  ),
                  _divider(),
                  _MenuRow(
                    icon: Icons.ac_unit_rounded,
                    emoji: '❄️',
                    label: 'Freeze Days',
                    color: AppColors.welfareBlue,
                    trailing: '${user?.freezesRemaining ?? 0} left',
                    onTap: () => _push(context, const FreezeDaysScreen()),
                  ),
                ],
              ),
            ),
          ),

          // ── 5. Invite friends ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.15),
                        AppColors.welfareBlue.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withOpacity(0.35)),
                  ),
                  child: const Row(
                    children: [
                      Text('👥', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invite Friends',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkTextPrimary)),
                            Text(
                              'Challenge friends and climb the leaderboard',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.darkTextSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.darkBorder, indent: 56);

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

/// ─── NEW Profile Hero Section (Background Image, Avatar, User Info) ──────────
class _ProfileHeroSection extends StatelessWidget {
  final dynamic user; // Replace 'dynamic' with your actual UserModel type
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;

  const _ProfileHeroSection({
    required this.user,
    required this.onSettingsTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/profileBg.png'), // <--- YOUR SCENIC BACKGROUND
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay to seamlessly fade into darkBg at the bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.darkBg.withOpacity(0.4),
                    AppColors.darkBg,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Safe Area content on top of background
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Bar (Profile Title & Settings Icon ONLY)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, // Changed to white to show over image
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                        onPressed: onSettingsTap,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Spacing above avatar

                // Avatar with Edit Button
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Inside _ProfileHeroSection
                    CustomAvatar(
                      url: user?.profilePicture,
                      name: user?.name ?? '',
                      size: 96,
                    ),
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.flameOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkBg, width: 3),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user?.name ?? 'Riyan',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),

                // Username (Kept exactly as requested)
                Text(
                  '@${user?.username ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),

                // Bio (Kept exactly as requested)
                if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.bio!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── NEW Separated Level & XP Card (Matches UI) ─────────────────────────────
class _LevelXpCard extends StatelessWidget {
  final int level;
  final int currentXp;
  final int nextLevelXp;

  const _LevelXpCard({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {

    final int totalXpForNextLevel = currentXp + nextLevelXp;
    final double progress = totalXpForNextLevel > 0
        ? (currentXp / totalXpForNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161324), // Dark card surface
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Mountain Icon (Using built-in Material icon as requested)
              const Icon(Icons.terrain_rounded, color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              Text('Level $level',style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),

              Text('$currentXp / $totalXpForNextLevel XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Orange glowing progress bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2A263E), // Dark rail
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A00), Color(0xFFFFB67A)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF8A00).withOpacity(0.4), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile (Unchanged) ───────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 1),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.darkTextSecondary,
                    height: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── Menu row (Unchanged) ─────────────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary)),
            ),
            if (trailing != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.welfareBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trailing!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.welfareBlue,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.darkTextSecondary),
          ],
        ),
      ),
    );
  }
}