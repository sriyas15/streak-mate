import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

// ─── Milestone definitions ────────────────────────────────────────────────────
class _Milestone {
  final int level;
  final String title;
  final String emoji;
  final String description;
  const _Milestone(this.level, this.title, this.emoji, this.description);
}

const _milestones = [
  _Milestone(1,  'Starting Today',      '🌱', 'Every great journey begins with a single step.'),
  _Milestone(2,  'Getting Stronger',    '💪', 'You\'re building the habit muscle.'),
  _Milestone(3,  'Finding Rhythm',      '🎵', 'Consistency is becoming second nature.'),
  _Milestone(4,  'Building Discipline', '🧱', 'Your habits are shaping your character.'),
  _Milestone(5,  'Rising Higher',       '⛰️', 'The higher you climb, the better the view.'),
  _Milestone(6,  'Unstoppable',         '🚀', 'Nothing can break your momentum now.'),
  _Milestone(7,  'Champion',            '🏆', 'You\'ve mastered the art of consistency.'),
  _Milestone(8,  'Legend',              '👑', 'Your discipline inspires everyone around you.'),
  _Milestone(9,  'Mythic',              '⚡', 'Beyond ordinary. You\'ve rewritten your story.'),
  _Milestone(10, 'Peak of Mastery',     '🌟', 'The summit. Few ever reach this height.'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentLevel = user?.level ?? 1;
    final xp          = user?.xpPoints ?? 0;
    final xpToNext    = user?.xpToNextLevel ?? 100;
    final xpTotal     = xp + xpToNext; // total XP needed for next level
    final streak      = user?.currentStreakDays ?? 0;

    // Reversed so highest level is at the top
    final items = _milestones.reversed.toList();

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
                  const Text(
                    'My Journey',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep going — the path only gets better.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.darkTextSecondary),
                  ),
                  const SizedBox(height: 14),
                  // Stat chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                          emoji: '🔥',
                          label: '$streak day streak',
                          color: AppColors.flameOrange),
                      _StatChip(
                          emoji: '⭐',
                          label: 'Level $currentLevel',
                          color: AppColors.xpGold),
                      _StatChip(
                          emoji: '✨',
                          label: '$xp XP',
                          color: AppColors.prayerPurple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // XP bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Lv $currentLevel',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.xpGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: xpTotal > 0
                                  ? (xp / xpTotal).clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 8,
                              backgroundColor: AppColors.darkBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.xpGold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$xp / $xpTotal XP',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Winding path ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final m = items[index];
                  final unlocked = currentLevel >= m.level;
                  final isCurrent = currentLevel == m.level;
                  // Alternate sides: top item (highest level) starts right
                  // index 0 = highest = right, index 1 = left, etc.
                  final alignRight = index % 2 == 0;
                  final isLast = index == items.length - 1;

                  return _PathNode(
                    milestone: m,
                    unlocked: unlocked,
                    isCurrent: isCurrent,
                    alignRight: alignRight,
                    isLast: isLast,
                    currentLevel: currentLevel,
                    nextMilestone: index > 0 ? items[index - 1] : null,
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

// ─── Path Node ────────────────────────────────────────────────────────────────
class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.milestone,
    required this.unlocked,
    required this.isCurrent,
    required this.alignRight,
    required this.isLast,
    required this.currentLevel,
    required this.nextMilestone,
  });

  final _Milestone milestone;
  final bool unlocked;
  final bool isCurrent;
  final bool alignRight;
  final bool isLast;
  final int currentLevel;
  final _Milestone? nextMilestone;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final nodeW = screenW * 0.62;
    final circleSize = 60.0;
    final pathColor = unlocked
        ? AppColors.flameOrange.withOpacity(0.6)
        : AppColors.darkBorder.withOpacity(0.4);

    // Glow color for unlocked nodes
    final glowColor = isCurrent
        ? AppColors.flameOrange
        : unlocked
            ? AppColors.xpGold
            : AppColors.darkBorder;

    return Column(
      children: [
        // ── Node row ────────────────────────────────────────────
        SizedBox(
          height: 110,
          child: Stack(
            children: [
              // Connector line going downward to next node
              if (!isLast)
                Positioned(
                  bottom: 0,
                  left: alignRight
                      ? screenW * 0.5 - circleSize / 2 - 8
                      : screenW * 0.5 + circleSize / 2 - 8,
                  child: CustomPaint(
                    size: Size(circleSize + 16, 30),
                    painter: _CurvePainter(
                      color: pathColor,
                      goRight: !alignRight,
                    ),
                  ),
                ),

              // Island card
              Positioned(
                top: 10,
                left: alignRight ? null : 16,
                right: alignRight ? 16 : null,
                child: _IslandCard(
                  milestone: milestone,
                  unlocked: unlocked,
                  isCurrent: isCurrent,
                  width: nodeW,
                  glowColor: glowColor,
                ),
              ),

              // Circle badge on the opposite side
              Positioned(
                top: 22,
                left: alignRight
                    ? 16
                    : screenW - 16 - circleSize,
                child: _CircleBadge(
                  milestone: milestone,
                  unlocked: unlocked,
                  isCurrent: isCurrent,
                  size: circleSize,
                  glowColor: glowColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Island Card ─────────────────────────────────────────────────────────────
class _IslandCard extends StatelessWidget {
  const _IslandCard({
    required this.milestone,
    required this.unlocked,
    required this.isCurrent,
    required this.width,
    required this.glowColor,
  });

  final _Milestone milestone;
  final bool unlocked;
  final bool isCurrent;
  final double width;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.flameOrange.withOpacity(0.12)
            : unlocked
                ? AppColors.darkSurface
                : AppColors.darkSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? AppColors.flameOrange
              : unlocked
                  ? glowColor.withOpacity(0.5)
                  : AppColors.darkBorder.withOpacity(0.3),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.flameOrange.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : unlocked
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.1),
                      blurRadius: 8,
                    )
                  ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? AppColors.darkTextPrimary
                        : AppColors.darkTextSecondary.withOpacity(0.5),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: unlocked
                      ? glowColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv ${milestone.level}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? glowColor
                        : AppColors.darkTextSecondary.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            milestone.description,
            style: TextStyle(
              fontSize: 11,
              color: unlocked
                  ? AppColors.darkTextSecondary
                  : AppColors.darkTextSecondary.withOpacity(0.35),
            ),
            maxLines: 2,
          ),
          if (isCurrent) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.flameOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '📍 You are here',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.flameOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Circle Badge ─────────────────────────────────────────────────────────────
class _CircleBadge extends StatelessWidget {
  const _CircleBadge({
    required this.milestone,
    required this.unlocked,
    required this.isCurrent,
    required this.size,
    required this.glowColor,
  });

  final _Milestone milestone;
  final bool unlocked;
  final bool isCurrent;
  final double size;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? AppColors.flameOrange.withOpacity(0.2)
            : unlocked
                ? glowColor.withOpacity(0.15)
                : AppColors.darkSurface,
        border: Border.all(
          color: isCurrent
              ? AppColors.flameOrange
              : unlocked
                  ? glowColor.withOpacity(0.6)
                  : AppColors.darkBorder.withOpacity(0.3),
          width: isCurrent ? 2 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.flameOrange.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              ]
            : unlocked
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.2),
                      blurRadius: 8,
                    )
                  ]
                : null,
      ),
      child: Center(
        child: unlocked
            ? Text(milestone.emoji,
                style: TextStyle(fontSize: isCurrent ? 26 : 22))
            : Icon(
                Icons.lock_rounded,
                color: AppColors.darkTextSecondary.withOpacity(0.3),
                size: 22,
              ),
      ),
    );
  }
}

// ─── Curve Painter (path connector) ──────────────────────────────────────────
class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.color, required this.goRight});
  final Color color;
  final bool goRight; // true = curve goes to the right side

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (goRight) {
      path.moveTo(size.width * 0.2, 0);
      path.quadraticBezierTo(
          size.width * 0.8, size.height * 0.5, size.width, size.height);
    } else {
      path.moveTo(size.width * 0.8, 0);
      path.quadraticBezierTo(
          size.width * 0.2, size.height * 0.5, 0, size.height);
    }

    // Dashed effect
    final dashPath = Path();
    const dashWidth = 8.0;
    const dashSpace = 5.0;
    var distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.color != color || old.goRight != goRight;
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.emoji, required this.label, required this.color});
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}