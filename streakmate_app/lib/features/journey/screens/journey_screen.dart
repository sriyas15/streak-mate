import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

// ─── Milestone definitions ────────────────────────────────────────────────────
class _Milestone {
  final int level;
  final String title;
  final String emoji;

  // Position as fraction of image dimensions (853 × 1844)
  final double fx;
  final double fy;

  // Label card appears on left or right of the glow dot
  final bool labelOnLeft;

  const _Milestone({
    required this.level,
    required this.title,
    required this.emoji,
    required this.fx,
    required this.fy,
    required this.labelOnLeft,
  });
}

// Positions measured from journey_marked2.png
const _milestones = [
  _Milestone(level: 1,  title: 'Starting Today',      emoji: '🌱', fx: 0.42, fy: 0.755, labelOnLeft: false),
  _Milestone(level: 2,  title: 'Getting Stronger',    emoji: '💪', fx: 0.52, fy: 0.545, labelOnLeft: true),
  _Milestone(level: 3,  title: 'Finding Rhythm',      emoji: '🎵', fx: 0.35, fy: 0.435, labelOnLeft: false),
  _Milestone(level: 5,  title: 'Building Discipline', emoji: '🧱', fx: 0.46, fy: 0.295, labelOnLeft: true),
  _Milestone(level: 10, title: 'Peak of Mastery',     emoji: '🌟', fx: 0.52, fy: 0.118, labelOnLeft: false),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(authProvider).user;
    final currentLevel = user?.level ?? 1;
    final xp           = user?.xpPoints ?? 0;
    final xpToNext     = user?.xpToNextLevel ?? 100;
    final streak       = user?.currentStreakDays ?? 0;
    final firstName    = user?.name.split(' ').first ?? 'Champion';

    final screenW = MediaQuery.sizeOf(context).width;
    // Preserve image aspect ratio 853 × 1844
    final imgH = screenW * (1844 / 853);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header ─────────────────────────────────────
            _Header(
              streak: streak,
              currentLevel: currentLevel,
              xp: xp,
              xpToNext: xpToNext,
            ),

            // ── Scrollable journey map ────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: screenW,
                  height: imgH,
                  child: Stack(
                    children: [
                      // Background — fills entire Stack
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/journey2.png',
                          fit: BoxFit.fill,
                        ),
                      ),

                      // Milestone overlays
                      ..._milestones.map((m) {
                        final unlocked  = currentLevel >= m.level;
                        final isCurrent = currentLevel == m.level;
                        final dotX = screenW * m.fx;
                        final dotY = imgH    * m.fy;
                        return _MilestoneOverlay(
                          milestone:  m,
                          dotX:       dotX,
                          dotY:       dotY,
                          unlocked:   unlocked,
                          isCurrent:  isCurrent,
                          screenW:    screenW,
                        );
                      }),

                      // Bottom motivation banner
                      Positioned(
                        bottom: 32,
                        left:   16,
                        right:  16,
                        child:  _MotivationBanner(name: firstName),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int streak;
  final int currentLevel;
  final int xp;
  final int xpToNext;

  const _Header({
    required this.streak,
    required this.currentLevel,
    required this.xp,
    required this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    final total = xp + xpToNext;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppColors.darkBg,
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
          const SizedBox(height: 12),

          // Stat chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(emoji: '🔥', label: '$streak day streak', color: AppColors.flameOrange),
              _Chip(emoji: '⭐', label: 'Level $currentLevel',  color: AppColors.xpGold),
              _Chip(emoji: '✨', label: '$xp XP',               color: AppColors.prayerPurple),
            ],
          ),
          const SizedBox(height: 10),

          // XP progress bar
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.xpGold)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? (xp / total).clamp(0.0, 1.0) : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.darkBorder,
                      valueColor:
                      const AlwaysStoppedAnimation(AppColors.xpGold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$xp / $total XP',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Overlay ────────────────────────────────────────────────────────
class _MilestoneOverlay extends StatelessWidget {
  final _Milestone milestone;
  final double dotX;
  final double dotY;
  final bool unlocked;
  final bool isCurrent;
  final double screenW;

  const _MilestoneOverlay({
    required this.milestone,
    required this.dotX,
    required this.dotY,
    required this.unlocked,
    required this.isCurrent,
    required this.screenW,
  });

  @override
  Widget build(BuildContext context) {
    const dotR     = 20.0; // radius of glow circle
    const cardW    = 148.0;
    const cardGap  = 14.0; // gap between dot edge and card

    final glowColor = isCurrent
        ? AppColors.flameOrange
        : unlocked
        ? AppColors.xpGold
        : Colors.transparent;

    return Stack(
      children: [
        // ── Glow ring on island ──────────────────────────────────
        Positioned(
          left: dotX - dotR,
          top:  dotY - dotR,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width:  dotR * 2,
            height: dotR * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? glowColor.withOpacity(isCurrent ? 0.25 : 0.12)
                  : Colors.black.withOpacity(0.45),
              border: Border.all(
                color: unlocked
                    ? glowColor.withOpacity(isCurrent ? 1.0 : 0.55)
                    : Colors.white.withOpacity(0.15),
                width: isCurrent ? 2.5 : 1.5,
              ),
              boxShadow: unlocked
                  ? [
                BoxShadow(
                  color: glowColor
                      .withOpacity(isCurrent ? 0.65 : 0.25),
                  blurRadius:   isCurrent ? 28 : 12,
                  spreadRadius: isCurrent ? 6  : 2,
                ),
              ]
                  : null,
            ),
            child: Center(
              child: unlocked
                  ? Text(milestone.emoji,
                  style:
                  TextStyle(fontSize: isCurrent ? 18 : 14))
                  : const Icon(Icons.lock_rounded,
                  color: Colors.white24, size: 14),
            ),
          ),
        ),

        // ── Label card ───────────────────────────────────────────
        Positioned(
          left: milestone.labelOnLeft
              ? (dotX - dotR - cardGap - cardW)
              .clamp(4.0, screenW - cardW - 4)
              : (dotX + dotR + cardGap)
              .clamp(4.0, screenW - cardW - 4),
          top: dotY - 34,
          child: _LabelCard(
            milestone:  milestone,
            unlocked:   unlocked,
            isCurrent:  isCurrent,
            glowColor:  glowColor,
          ),
        ),
      ],
    );
  }
}

// ─── Label Card ───────────────────────────────────────────────────────────────
class _LabelCard extends StatelessWidget {
  final _Milestone milestone;
  final bool unlocked;
  final bool isCurrent;
  final Color glowColor;

  const _LabelCard({
    required this.milestone,
    required this.unlocked,
    required this.isCurrent,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(isCurrent ? 0.78 : 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? glowColor.withOpacity(0.8)
              : unlocked
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.07),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [
          BoxShadow(
            color:       glowColor.withOpacity(0.35),
            blurRadius:  18,
            spreadRadius: 2,
          )
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            milestone.title,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color: unlocked
                  ? Colors.white.withOpacity(0.95)
                  : Colors.white.withOpacity(0.3),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Level ${milestone.level}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: unlocked
                  ? glowColor.withOpacity(0.9)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.flameOrange.withOpacity(0.22),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '📍 You are here',
                style: TextStyle(
                  fontSize:   9,
                  color:      AppColors.flameOrange,
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

// ─── Motivation Banner ────────────────────────────────────────────────────────
class _MotivationBanner extends StatelessWidget {
  final String name;
  const _MotivationBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.xpGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep going, $name!',
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.xpGold)),
                const SizedBox(height: 2),
                Text('Every step forward is a win.',
                    style: TextStyle(
                        fontSize: 11,
                        color:    Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color  color;
  const _Chip(
      {required this.emoji, required this.label, required this.color});

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
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      color)),
        ],
      ),
    );
  }
}