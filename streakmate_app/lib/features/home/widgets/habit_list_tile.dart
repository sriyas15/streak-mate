import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/habit_log_model.dart';
import '../../../models/remote/subtask_model.dart';

/// habit_list_tile.dart
/// Expandable habit card matching image 2's "Setup Workout" card:
///  - Header row: icon + name + mini progress + streak count
///  - Expands to show subtask list with checkboxes
///  - Subtask tap calls onSubtaskToggle
class HabitListTile extends StatefulWidget {
  const HabitListTile({
    super.key,
    required this.habit,
    required this.subtasks,
    required this.onSubtaskToggle,
    this.isLoading = false,
    this.initiallyExpanded = false,
    this.onHeaderTap
  });

  final TodayHabitModel habit;
  final List<SubtaskModel> subtasks;
  final void Function(String subtaskId, bool currentValue) onSubtaskToggle;
  final bool isLoading;
  final bool initiallyExpanded;
  final VoidCallback? onHeaderTap;

  @override
  State<HabitListTile> createState() => _HabitListTileState();
}

class _HabitListTileState extends State<HabitListTile>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (_expanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final color = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
    final log = habit.todayLog;
    final done = habit.isCompleted;
    final pct = habit.completionPercentage;
    final completedCount = log?.subtaskResults.where((r) => r.isCompleted).length ?? 0;
    final total = widget.subtasks.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? color.withOpacity(0.5) : AppColors.darkBorder,
          width: done ? 1.2 : 1,
        ),
        boxShadow: done
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12)]
            : null,
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          InkWell(
            onTap: widget.onHeaderTap ?? _toggle,  // navigate if provided, else expand
            onLongPress: widget.onHeaderTap != null ? _toggle : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(habit.icon,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 4,
                            backgroundColor: AppColors.darkBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                done ? AppColors.success : color),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$completedCount/$total tasks',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Streak badge
                  if (habit.currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.flameOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 2),
                          Text(
                            '${habit.currentStreak}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.flameOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.darkTextSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // ── Subtask list (animated expand) ──────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(color: AppColors.darkBorder, height: 1),
                  const SizedBox(height: 10),
                  ...widget.subtasks.map((subtask) {
                    final result = log?.subtaskResults.firstWhere(
                      (r) => r.subtaskId == subtask.id,
                      orElse: () => SubtaskResult(
                          subtaskId: subtask.id, isCompleted: false),
                    );
                    final isDone = result?.isCompleted ?? false;
                    return _SubtaskRow(
                      subtask: subtask,
                      isDone: isDone,
                      color: color,
                      isLoading: widget.isLoading,
                      onTap: isDone ? null : () => widget.onSubtaskToggle(subtask.id, isDone),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.isDone,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final SubtaskModel subtask;
  final bool isDone;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? color : Colors.transparent,
                border: Border.all(
                  color: isDone ? color : AppColors.darkBorder,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtask.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDone
                          ? AppColors.darkTextSecondary
                          : AppColors.darkTextPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.darkTextSecondary,
                    ),
                  ),
                  if (subtask.targetValue != null && subtask.unit != null)
                    Text(
                      '${subtask.targetValue} ${subtask.unit}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary),
                    ),
                ],
              ),
            ),
            if (!subtask.isRequired)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.darkTextSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
