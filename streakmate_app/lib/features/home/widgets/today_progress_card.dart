import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/habit_log_model.dart';

/// today_progress_card.dart
/// "Today's Journey" section from image 2:
///  - Section header with X/Y completed
///  - Horizontal progress bar
///  - Row of habit icon chips (completed = colored, incomplete = dim)
class TodayProgressCard extends StatelessWidget {
  const TodayProgressCard({
    super.key,
    required this.habits,
    required this.onHabitTap,
  });

  final List<TodayHabitModel> habits;
  final ValueChanged<TodayHabitModel> onHabitTap;

  @override
  Widget build(BuildContext context) {
    final completed = habits.where((h) => h.isCompleted).length;
    final total = habits.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Journey',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              Text(
                '$completed/$total completed',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.darkBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.success : AppColors.flameOrange,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Habit icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: habits.map((habit) {
              return _HabitChip(habit: habit, onTap: () => onHabitTap(habit));
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  const _HabitChip({required this.habit, required this.onTap});
  final TodayHabitModel habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
    final done = habit.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color.withOpacity(0.25) : AppColors.darkSurfaceElevated,
              border: Border.all(
                color: done ? color : AppColors.darkBorder,
                width: done ? 2 : 1,
              ),
              boxShadow: done
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]
                  : null,
            ),
            child: Center(
              child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 6),
          if (done)
            const Icon(Icons.check_circle, size: 14, color: AppColors.success)
          else
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
