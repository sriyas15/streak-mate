import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.userName,
    required this.streakDays,
    required this.level,
    required this.xpPoints,
    required this.xpToNextLevel,
    this.imagePath,
  });

  final String userName;
  final int streakDays;
  final int level;
  final int xpPoints;
  final int xpToNextLevel;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 196,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imagePath != null
                    ? Image.asset(imagePath!, fit: BoxFit.cover)
                    : _GradientPlaceholder(userName: userName),
                Positioned(
                  left: 0, right: 0, bottom: 0, height: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16, right: 80, bottom: 14,
                  child: Text(
                    '"Discipline today, freedom tomorrow."',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.75)),
                    maxLines: 2,
                  ),
                ),
                Positioned(
                  right: 14, bottom: 10,
                  child: _StreakCircle(days: streakDays),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _XpBar(level: level, xp: xpPoints, xpMax: xpToNextLevel),
      ],
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.userName});
  final String userName;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1040), Color(0xFF2D1F5E), Color(0xFF1A2744)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.prayerPurple.withOpacity(0.3), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: 40,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.welfareBlue.withOpacity(0.25), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            top: 20, left: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good ${_greeting()}, $userName! 👋',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Let\'s make today count.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.image_outlined, size: 32, color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 6),
                Text('Drop home_scene.png here',
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.18))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCircle extends StatelessWidget {
  const _StreakCircle({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66, height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2A33D), Color(0xFFE8762B)],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: AppColors.flameOrange.withOpacity(0.55), blurRadius: 18, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18, height: 1)),
          Text('$days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
          Text('days', style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.level, required this.xp, required this.xpMax});
  final int level;
  final int xp;
  final int xpMax;

  @override
  Widget build(BuildContext context) {
    final progress = xpMax > 0 ? (xp / xpMax).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF2A33D), Color(0xFFE8762B)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Lv $level',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 7,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.xpGold),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$xp / $xpMax XP',
                    style: const TextStyle(fontSize: 10, color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 18)),
              Text('Next', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
            ],
          ),
        ],
      ),
    );
  }
}