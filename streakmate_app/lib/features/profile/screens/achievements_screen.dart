import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/achievement_model.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/auth_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Achievements',
            style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.flameOrange)),
        error: (_, __) =>
            _Body(achievements: AchievementModel.defaults, user: user),
        data: (achievements) =>
            _Body(achievements: achievements, user: user),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.achievements, required this.user});
  final List<AchievementModel> achievements;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    return CustomScrollView(
      slivers: [
        // ── Summary banner ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1F00), Color(0xFF3D2D00)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.xpGold.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Text('🏆',
                    style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${unlocked.length} / ${achievements.length}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.xpGold),
                      ),
                      const Text('Achievements unlocked',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkTextSecondary)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievements.isEmpty
                              ? 0
                              : unlocked.length / achievements.length,
                          minHeight: 6,
                          backgroundColor:
                              AppColors.xpGold.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.xpGold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Unlocked section ─────────────────────────────────────
        if (unlocked.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text('✅ Unlocked',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _AchievementCard(achievement: unlocked[i]),
                childCount: unlocked.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
            ),
          ),
        ],

        // ── Locked section ───────────────────────────────────────
        if (locked.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('🔒 Locked',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) =>
                    _AchievementCard(achievement: locked[i]),
                childCount: locked.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});
  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.xpGold.withOpacity(0.1)
              : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.xpGold.withOpacity(0.4)
                : AppColors.darkBorder,
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                      color: AppColors.xpGold.withOpacity(0.15),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  achievement.icon,
                  style: TextStyle(
                      fontSize: 32,
                      color: unlocked
                          ? null
                          : Colors.white.withOpacity(0.08)),
                ),
                if (!unlocked)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.darkBorder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        size: 14,
                        color: AppColors.darkTextSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: unlocked
                      ? AppColors.darkTextPrimary
                      : AppColors.darkTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+${achievement.xpReward} XP',
              style: TextStyle(
                fontSize: 9,
                color: unlocked
                    ? AppColors.xpGold
                    : AppColors.darkTextSecondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AchievementDetail(achievement: achievement),
    );
  }
}

class _AchievementDetail extends StatelessWidget {
  const _AchievementDetail({required this.achievement});
  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(achievement.icon,
              style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(achievement.name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary)),
          const SizedBox(height: 6),
          Text(achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.darkTextSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.xpGold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('${achievement.xpReward} XP reward',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.xpGold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (unlocked && achievement.unlockedAt != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Unlocked ${_fmt(achievement.unlockedAt!)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.success),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🔒  Not yet unlocked',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary)),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day} ${_month(dt.month)} ${dt.year}';
  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}