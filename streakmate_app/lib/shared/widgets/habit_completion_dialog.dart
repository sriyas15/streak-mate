import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/habit_log_model.dart';
import '../../../providers/auth_provider.dart';

/// Call this to show the habit completion celebration dialog.
/// Pass the completed habit and a WidgetRef to read authProvider.
void showHabitCompletionDialog(
  BuildContext context,
  WidgetRef ref, {
  required String habitName,
  required String habitIcon,
  required String habitColor,
}) {
  final user = ref.read(authProvider).user;
  final xp = user?.xpPoints ?? 0;
  final level = user?.level ?? 1;
  final streak = user?.currentStreakDays ?? 0;
  final color =
      Color(int.parse(habitColor.replaceFirst('#', '0xFF')));

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.75),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => _HabitCompletionDialog(
      habitName: habitName,
      habitIcon: habitIcon,
      color: color,
      xp: xp,
      level: level,
      streak: streak,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
      );
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}

class _HabitCompletionDialog extends StatefulWidget {
  const _HabitCompletionDialog({
    required this.habitName,
    required this.habitIcon,
    required this.color,
    required this.xp,
    required this.level,
    required this.streak,
  });

  final String habitName;
  final String habitIcon;
  final Color color;
  final int xp;
  final int level;
  final int streak;

  @override
  State<_HabitCompletionDialog> createState() =>
      _HabitCompletionDialogState();
}

class _HabitCompletionDialogState extends State<_HabitCompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _statsController;
  late Animation<double> _starScale;
  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );

    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOut),
    );

    _statsSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _statsController, curve: Curves.easeOut));

    // Sequence: star pops first, then stats slide in
    _starController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _statsController.forward();
      });
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1530),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.color.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated star / mascot area ──────────────────────
              ScaleTransition(
                scale: _starScale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.15),
                    border: Border.all(
                      color: widget.color.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.habitIcon,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Title ─────────────────────────────────────────────
              const Text(
                'Amazing work! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You completed all your\n${widget.habitName} tasks today.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Animated stats row ────────────────────────────────
              SlideTransition(
                position: _statsSlide,
                child: FadeTransition(
                  opacity: _statsFade,
                  child: Row(
                    children: [
                      _StatBadge(
                        emoji: '🔥',
                        value: '${widget.streak}',
                        label: 'Streak',
                        color: AppColors.flameOrange,
                      ),
                      const SizedBox(width: 10),
                      _StatBadge(
                        emoji: '✨',
                        value: '${widget.xp}',
                        label: 'Total XP',
                        color: AppColors.xpGold,
                      ),
                      const SizedBox(width: 10),
                      _StatBadge(
                        emoji: '⭐',
                        value: 'Lv ${widget.level}',
                        label: 'Level',
                        color: AppColors.prayerPurple,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Current streak bar ────────────────────────────────
              SlideTransition(
                position: _statsSlide,
                child: FadeTransition(
                  opacity: _statsFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.flameOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppColors.flameOrange.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.streak > 0
                                ? 'You\'re on a ${widget.streak} day streak! Keep it up 💪'
                                : 'Great start! Build your streak tomorrow.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.flameOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Continue button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue Journey →',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}