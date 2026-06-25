import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/achievement_model.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text('Profile',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: AppColors.darkTextSecondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Avatar + name card ────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1040), Color(0xFF2D1F5E)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppColors.prayerPurple.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.flameOrange.withOpacity(0.8),
                                AppColors.xpGold.withOpacity(0.8),
                              ],
                            ),
                            border: Border.all(
                                color: AppColors.flameOrange, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.flameOrange.withOpacity(0.4),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _initials(user?.name ?? ''),
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.xpGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lv ${user?.level ?? 1}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      '@${user?.username ?? ''}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.flameOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.flameOrange.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Building better habits ✏️',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // XP bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${user?.xpPoints ?? 0} / ${user?.xpToNextLevel ?? 100} XP',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary),
                            ),
                            Text(
                              'Next: Level ${(user?.level ?? 1) + 1}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.xpGold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _xpProgress(
                                user?.xpPoints ?? 0,
                                user?.xpToNextLevel ?? 100),
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.xpGold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats row ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _StatCard(
                      emoji: '🔥',
                      value: '${user?.currentStreakDays ?? 0}',
                      label: 'Current\nStreak',
                      color: AppColors.flameOrange,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      emoji: '🏆',
                      value: '${user?.bestStreakDays ?? 0}',
                      label: 'Best\nStreak',
                      color: AppColors.xpGold,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      emoji: '❄️',
                      value: '${user?.freezesRemaining ?? 0}',
                      label: 'Freezes\nLeft',
                      color: AppColors.welfareBlue,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      emoji: '🎭',
                      value: '${user?.cheatDaysRemaining ?? 0}',
                      label: 'Cheat\nDays',
                      color: AppColors.prayerPurple,
                    ),
                  ],
                ),
              ),
            ),

            // ── Achievements section ──────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Achievements',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
              ),
            ),

            achievementsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: AppColors.flameOrange),
                )),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: _AchievementsGrid(
                    achievements: AchievementModel.defaults),
              ),
              data: (achievements) => SliverToBoxAdapter(
                child: _AchievementsGrid(achievements: achievements),
              ),
            ),

            // ── Settings list ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Settings',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _SettingsList(
                  onLogout: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  double _xpProgress(int xp, int max) =>
      max > 0 ? (xp / max).clamp(0.0, 1.0) : 0.0;
}

// ── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkTextSecondary,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ── Achievements grid ────────────────────────────────────────────────────────
class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.achievements});
  final List<AchievementModel> achievements;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();
    final sorted = [...unlocked, ...locked];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unlocked count chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.xpGold.withOpacity(0.3)),
            ),
            child: Text(
              '${unlocked.length} / ${achievements.length} unlocked',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.xpGold,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              return _AchievementBadge(achievement: sorted[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});
  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? AppColors.xpGold.withOpacity(0.15)
                  : AppColors.darkSurface,
              border: Border.all(
                color: unlocked
                    ? AppColors.xpGold.withOpacity(0.6)
                    : AppColors.darkBorder,
                width: unlocked ? 1.5 : 1,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                          color: AppColors.xpGold.withOpacity(0.2),
                          blurRadius: 8)
                    ]
                  : null,
            ),
            child: Center(
              child: unlocked
                  ? Text(achievement.icon,
                      style: const TextStyle(fontSize: 24))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(achievement.icon,
                            style: TextStyle(
                                fontSize: 22,
                                color:
                                    Colors.white.withOpacity(0.1))),
                        const Icon(Icons.lock_rounded,
                            size: 16,
                            color: AppColors.darkTextSecondary),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: unlocked
                  ? AppColors.darkTextPrimary
                  : AppColors.darkTextSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(achievement.icon,
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(achievement.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTextPrimary)),
            const SizedBox(height: 6),
            Text(achievement.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.darkTextSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('${achievement.xpReward} XP reward',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.xpGold)),
              ],
            ),
            const SizedBox(height: 8),
            if (unlocked && achievement.unlockedAt != null)
              Text(
                'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.success),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🔒 Not yet unlocked',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary)),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

// ── Settings list ────────────────────────────────────────────────────────────
class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          _SettingRow(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {}),
          _Divider(),
          _SettingRow(
              icon: Icons.ac_unit_rounded,
              label: 'Freeze Days',
              trailing: 'Manage',
              onTap: () {}),
          _Divider(),
          _SettingRow(
              icon: Icons.calendar_today_outlined,
              label: 'Habit Reminders',
              onTap: () {}),
          _Divider(),
          _SettingRow(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {}),
          _Divider(),
          _SettingRow(
            icon: Icons.logout_rounded,
            label: 'Log out',
            color: AppColors.danger,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Log out?',
            style: TextStyle(color: AppColors.darkTextPrimary)),
        content: const Text('You can always log back in.',
            style: TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
            },
            child: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.darkTextPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        color: c,
                        fontWeight: FontWeight.w500))),
            if (trailing != null)
              Text(trailing!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.darkTextSecondary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.darkTextSecondary),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.darkBorder, indent: 50);
}
