import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

// ─── Journey milestone definitions ──────────────────────────────────────────
class _Milestone {
  final int level;
  final String title;
  final String emoji;
  final String description;
  const _Milestone(this.level, this.title, this.emoji, this.description);
}

const _milestones = [
  _Milestone(1, 'Starting Today', '🌱', 'Every great journey begins with a single step.'),
  _Milestone(2, 'Getting Stronger', '💪', 'You\'re building the habit muscle.'),
  _Milestone(3, 'Finding Rhythm', '🎵', 'Consistency is becoming second nature.'),
  _Milestone(4, 'Building Discipline', '🧱', 'Your habits are shaping your character.'),
  _Milestone(5, 'Rising Higher', '⛰️', 'The higher you climb, the better the view.'),
  _Milestone(6, 'Unstoppable', '🚀', 'Nothing can break your momentum now.'),
  _Milestone(7, 'Champion', '🏆', 'You\'ve mastered the art of consistency.'),
  _Milestone(8, 'Legend', '👑', 'Your discipline inspires everyone around you.'),
  _Milestone(9, 'Mythic', '⚡', 'Beyond ordinary. You\'ve rewritten your story.'),
  _Milestone(10, 'Peak of Mastery', '🌟', 'The summit. Few ever reach this height.'),
];

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentLevel = user?.level ?? 1;
    final xp = user?.xpPoints ?? 0;
    final xpMax = user?.xpToNextLevel ?? 100;
    final streak = user?.currentStreakDays ?? 0;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Journey',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary)),
                  const SizedBox(height: 4),
                  Text('Keep going — the path only gets better.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(emoji: '🔥', label: '$streak day streak', color: AppColors.flameOrange),
                      const SizedBox(width: 10),
                      _StatChip(emoji: '⭐', label: 'Level $currentLevel', color: AppColors.xpGold),
                      const SizedBox(width: 10),
                      _StatChip(emoji: '✨', label: '$xp XP', color: AppColors.prayerPurple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // XP bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        Text('Lv $currentLevel',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.xpGold)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: xpMax > 0 ? (xp / xpMax).clamp(0.0, 1.0) : 0,
                              minHeight: 8,
                              backgroundColor: AppColors.darkBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.xpGold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$xp/$xpMax',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.darkTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Winding path ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _milestones.length,
                itemBuilder: (context, index) {
                  // Render in reverse so highest level is at top
                  final i = _milestones.length - 1 - index;
                  final m = _milestones[i];
                  final unlocked = currentLevel >= m.level;
                  final isCurrent = currentLevel == m.level;
                  return _MilestoneNode(
                    milestone: m,
                    unlocked: unlocked,
                    isCurrent: isCurrent,
                    isLast: index == _milestones.length - 1,
                    alignLeft: i % 2 == 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.emoji, required this.label, required this.color});
  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _MilestoneNode extends StatelessWidget {
  const _MilestoneNode({
    required this.milestone,
    required this.unlocked,
    required this.isCurrent,
    required this.isLast,
    required this.alignLeft,
  });

  final _Milestone milestone;
  final bool unlocked;
  final bool isCurrent;
  final bool isLast;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.flameOrange : AppColors.darkBorder;
    final bgColor = isCurrent
        ? AppColors.flameOrange.withOpacity(0.18)
        : unlocked
            ? AppColors.darkSurfaceElevated
            : AppColors.darkSurface;

    return Column(
      children: [
        // Connector line above (except first from top which is last item)
        if (!isLast)
          Container(
            width: 2,
            height: 28,
            color: unlocked ? AppColors.flameOrange.withOpacity(0.5) : AppColors.darkBorder,
          ),
        // Node
        Row(
          mainAxisAlignment:
              alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (!alignLeft) const Spacer(),
            Container(
              width: 260,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrent ? AppColors.flameOrange : color.withOpacity(0.4),
                  width: isCurrent ? 1.5 : 1,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: AppColors.flameOrange.withOpacity(0.2), blurRadius: 12)]
                    : null,
              ),
              child: Row(
                children: [
                  // Emoji badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: unlocked ? color.withOpacity(0.15) : AppColors.darkBorder.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: unlocked
                          ? Text(milestone.emoji, style: const TextStyle(fontSize: 22))
                          : const Icon(Icons.lock_rounded,
                              color: AppColors.darkTextSecondary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                milestone.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: unlocked ? AppColors.darkTextPrimary : AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: unlocked ? color.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Lv ${milestone.level}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: unlocked ? color : AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          milestone.description,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.darkTextSecondary),
                          maxLines: 2,
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.flameOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('📍 You are here',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.flameOrange,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (alignLeft) const Spacer(),
          ],
        ),
      ],
    );
  }
}