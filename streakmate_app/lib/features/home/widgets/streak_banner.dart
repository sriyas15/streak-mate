import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// streak_banner.dart
/// The illustrated top section of the Home screen from image 2:
///  - Dark gradient background
///  - Illustrated tree/house scene (gradient placeholder — swap for asset)
///  - Circular streak counter overlaid bottom-right of illustration
///  - XP level progress bar below
class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.userName,
    required this.streakDays,
    required this.level,
    required this.xpPoints,
    required this.xpToNextLevel,
  });

  final String userName;
  final int streakDays;
  final int level;
  final int xpPoints;
  final int xpToNextLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Illustrated scene card ─────────────────────────────────
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1040), Color(0xFF2D1F5E), Color(0xFF1A2744)],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Stars / ambient particles
              ..._buildStars(),
              // Illustrated scene placeholder — replace with:
              // Image.asset('assets/images/home_scene.png', fit: BoxFit.cover)
              const _ScenePlaceholder(),
              // Greeting overlay top-left
              Positioned(
                top: 16,
                left: 18,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_greeting()}, $userName! 👋',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Let\'s make today count.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              // Streak circle — bottom right
              Positioned(
                bottom: 16,
                right: 18,
                child: _StreakCircle(days: streakDays),
              ),
              // Quote overlay bottom left
              Positioned(
                bottom: 18,
                left: 18,
                right: 90,
                child: Text(
                  '"Discipline today, freedom tomorrow."',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.55),
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── XP level progress bar ──────────────────────────────────
        _XpBar(level: level, xp: xpPoints, xpMax: xpToNextLevel),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  List<Widget> _buildStars() {
    final positions = [
      const Offset(0.15, 0.12),
      const Offset(0.45, 0.08),
      const Offset(0.75, 0.18),
      const Offset(0.88, 0.35),
      const Offset(0.3, 0.25),
      const Offset(0.6, 0.30),
    ];
    return positions.map((p) {
      return Positioned(
        left: p.dx * 360,
        top: p.dy * 200,
        child: Container(
          width: 2,
          height: 2,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }).toList();
  }
}

class _StreakCircle extends StatelessWidget {
  const _StreakCircle({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2A33D), Color(0xFFE8762B)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.flameOrange.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$days',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            'Day Streak',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⛰️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$xp / $xpMax XP',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.darkBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.xpGold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painted placeholder for the illustrated home scene.
/// Replace with Image.asset once real art is added.
class _ScenePlaceholder extends StatelessWidget {
  const _ScenePlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _ScenePainter(),
    );
  }
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ground
    final groundPaint = Paint()..color = const Color(0xFF1A3318);
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.65, size.width, size.height),
      groundPaint,
    );
    // Tree trunk
    final trunkPaint = Paint()..color = const Color(0xFF5C3A1E);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.40, 18, size.height * 0.30),
      trunkPaint,
    );
    // Tree canopy — layered circles (purple glowing tree from image 2)
    final canopyColors = [
      const Color(0xFF6B48C2),
      const Color(0xFF8B5CF6),
      const Color(0xFFA78BFA),
    ];
    final canopyCenters = [
      Offset(size.width * 0.47, size.height * 0.30),
      Offset(size.width * 0.38, size.height * 0.38),
      Offset(size.width * 0.56, size.height * 0.36),
    ];
    final canopyRadii = [38.0, 28.0, 24.0];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        canopyCenters[i],
        canopyRadii[i],
        Paint()
          ..color = canopyColors[i]
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    // House
    final housePaint = Paint()..color = const Color(0xFF2D4A3E);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.52, 55, 40),
      housePaint,
    );
    // Roof
    final roofPath = Path()
      ..moveTo(size.width * 0.60, size.height * 0.52)
      ..lineTo(size.width * 0.645, size.height * 0.38)
      ..lineTo(size.width * 0.695, size.height * 0.52)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF1A3A2E));
    // Window glow
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.645, size.height * 0.56, 14, 12),
      Paint()
        ..color = const Color(0xFFF2C94C).withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
