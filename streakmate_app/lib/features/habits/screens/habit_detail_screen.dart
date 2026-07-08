import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/remote/habit_log_model.dart';
import '../../../models/remote/subtask_model.dart';
import '../../../providers/home_provider.dart';
import '../../../repositories/home_repository.dart';
import '../../../repositories/subtask_repository.dart';

// ─── Week Log Repository ──────────────────────────────────────────────────────

class HabitWeekRepository {
  HabitWeekRepository() : _dio = DioClient.instance.dio;
  final _dio;

  Future<Map<String, bool>> getWeekCompletion(String habitId) async {
    final now = DateTime.now();
    // Current week Mon–Sun
    final weekday = now.weekday; // Mon=1, Sun=7
    final monday = now.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final from = _fmt(monday);
    final to = _fmt(sunday);

    try {
      final r = await _dio.get(
        '${ApiEndpoints.habitLogs(habitId)}/range',
        queryParameters: {'from': from, 'to': to},
      );
      if (r.statusCode == 200) {
        final logs = r.data['data']['logs'] as List;
        final map = <String, bool>{};
        for (final log in logs) {
          map[log['date'] as String] = log['isCompleted'] as bool? ?? false;
        }
        return map;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class HabitDetailState {
  final bool loading;
  final bool marking;
  final HabitLogModel? log;
  final List<SubtaskModel> subtasks;
  final Map<String, bool> weekCompletion; // "YYYY-MM-DD" → isCompleted
  final String? error;

  const HabitDetailState({
    this.loading = false,
    this.marking = false,
    this.log,
    this.subtasks = const [],
    this.weekCompletion = const {},
    this.error,
  });

  HabitDetailState copyWith({
    bool? loading,
    bool? marking,
    HabitLogModel? log,
    List<SubtaskModel>? subtasks,
    Map<String, bool>? weekCompletion,
    String? error,
  }) =>
      HabitDetailState(
        loading: loading ?? this.loading,
        marking: marking ?? this.marking,
        log: log ?? this.log,
        subtasks: subtasks ?? this.subtasks,
        weekCompletion: weekCompletion ?? this.weekCompletion,
        error: error,
      );

  int get completedCount =>
      log?.subtaskResults.where((r) => r.isCompleted).length ?? 0;
  bool get isCompleted => log?.isCompleted ?? false;
  int get completionPercentage => log?.completionPercentage ?? 0;
}

class HabitDetailNotifier extends StateNotifier<HabitDetailState> {
  HabitDetailNotifier(this._subtaskRepo, this._homeRepo, this._weekRepo)
      : super(const HabitDetailState());

  final SubtaskRepository _subtaskRepo;
  final HomeRepository _homeRepo;
  final HabitWeekRepository _weekRepo;

  Future<void> init(String habitId, TodayHabitModel habit) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _subtaskRepo.getSubtasks(habitId),
        _weekRepo.getWeekCompletion(habitId),
      ]);
      state = state.copyWith(
        loading: false,
        subtasks: results[0] as List<SubtaskModel>,
        weekCompletion: results[1] as Map<String, bool>,
        log: habit.todayLog,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> toggleSubtask(
      String habitId, String subtaskId, bool currentValue) async {
    if (state.log == null) {
      try {
        final log = await _homeRepo.createLog(habitId);
        state = state.copyWith(log: log);
      } on ApiException catch (e) {
        state = state.copyWith(error: e.message);
        return;
      }
    }

    // Optimistic update
    final results = state.log!.subtaskResults.map((r) {
      if (r.subtaskId != subtaskId) return r;
      return r.copyWith(isCompleted: !currentValue);
    }).toList();
    final completed = results.where((r) => r.isCompleted).length;
    final pct = results.isEmpty
        ? 0
        : ((completed / results.length) * 100).round();
    state = state.copyWith(
      log: state.log!.copyWith(
        subtaskResults: results,
        completionPercentage: pct,
      ),
    );

    try {
      final updated = await _homeRepo.updateSubtaskResult(
        habitId: habitId,
        subtaskId: subtaskId,
        isCompleted: !currentValue,
      );
      state = state.copyWith(log: updated);
    } on ApiException catch (e) {
      // Rollback
      final rolled = state.log!.subtaskResults.map((r) {
        if (r.subtaskId != subtaskId) return r;
        return r.copyWith(isCompleted: currentValue);
      }).toList();
      state = state.copyWith(
        log: state.log!.copyWith(subtaskResults: rolled),
        error: e.message,
      );
    }
  }

  Future<bool> markComplete(String habitId) async {
    state = state.copyWith(marking: true, error: null);
    try {
      if (state.log == null) {
        final log = await _homeRepo.createLog(habitId);
        state = state.copyWith(log: log);
      }
      final updated = await _homeRepo.markComplete(habitId);
      // Refresh week completion for today
      final week = await _weekRepo.getWeekCompletion(habitId);
      state = state.copyWith(
          marking: false, log: updated, weekCompletion: week);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(marking: false, error: e.message);
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final _weekRepo = HabitWeekRepository();

final habitDetailProvider = StateNotifierProvider.autoDispose
    .family<HabitDetailNotifier, HabitDetailState, String>(
      (ref, habitId) => HabitDetailNotifier(
    ref.watch(subtaskRepositoryProvider),
    HomeRepository(),
    _weekRepo,
  ),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habit});
  final TodayHabitModel habit;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(habitDetailProvider(widget.habit.id).notifier)
        .init(widget.habit.id, widget.habit));
    // In _HabitDetailScreenState.initState, after Future.microtask:
    debugPrint('[HabitDetail] currentStreak=${widget.habit.currentStreak} bestStreak=${widget.habit.bestStreak}');
  }

  @override
  Widget build(BuildContext context) {

    final homeHabits = ref.watch(homeProvider).habits;
    final updatedHabit = homeHabits.firstWhere(
          (h) => h.id == widget.habit.id,
      orElse: () => widget.habit,
    );
    final habit = widget.habit;
    final color = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
    final detail = ref.watch(habitDetailProvider(habit.id));

    ref.listen<HabitDetailState>(habitDetailProvider(habit.id), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.danger),
        );
        ref.read(habitDetailProvider(habit.id).notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(habit: updatedHabit, color: color),
          ),

          // ── Current Streak + Weekly calendar ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _StreakAndWeekCard(
                  habit: updatedHabit, detail: detail, color: color),
            ),
          ),

          // ── Progress Journey ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ProgressCard(detail: detail, color: color),
            ),
          ),

          // ── Next Milestone ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _MilestoneCard(
                  currentStreak: habit.currentStreak, color: color),
            ),
          ),

          // ── Subtasks header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${detail.completedCount}/${detail.subtasks.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.flameOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Subtask list ─────────────────────────────────────────
          if (detail.loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.flameOrange),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                    final subtask = detail.subtasks[i];
                    final result = detail.log?.subtaskResults.firstWhere(
                          (r) => r.subtaskId == subtask.id,
                      orElse: () => SubtaskResult(
                          subtaskId: subtask.id, isCompleted: false),
                    );
                    final isDone = result?.isCompleted ?? false;
                    return _SubtaskTile(
                      subtask: subtask,
                      isDone: isDone,
                      color: color,
                      onTap: isDone
                      ? null
                      : () => ref
                            .read(habitDetailProvider(habit.id).notifier)
                            .toggleSubtask(habit.id, subtask.id, isDone),
                    );
                  },
                  childCount: detail.subtasks.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),

      // ── Bottom button ────────────────────────────────────────────
      bottomNavigationBar: _MarkCompleteButton(
        detail: detail,
        color: color,
        onTap: () async {
          final success = await ref
              .read(habitDetailProvider(habit.id).notifier)
              .markComplete(habit.id);
          if (success && context.mounted) {
            ref.read(homeProvider.notifier).loadToday();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Habit completed! 🎉'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────
String getBannerAsset(String habitName) {
  final name = habitName.toLowerCase();
  print("DEBUG: Habit name received is: '$name'");
  // Categorize based on what the habit is actually called
  if (name.contains('workout') || name.contains('gym') || name.contains('exercise')) {
    return 'assets/images/habit_1.png';
  }
  if (name.contains('prayer / quran') || name.contains('quran')) {
    return 'assets/images/habit_3.png';
  }
  if (name.contains('study')) {
    return 'assets/images/habit_2.png';
  }
  if (name.contains('diet')) {
    return 'assets/images/habit_4.png';
  }
  if (name.contains('personal welfare')) {
    return 'assets/images/habit_5.png';
  }

  return 'assets/images/habit_6.png'; // Fallback
}
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.habit, required this.color});
  final TodayHabitModel habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 460,
      child: Stack(
        children: [
          // 1. Image Background
          Positioned.fill(
            child: Image.asset(
              getBannerAsset(habit.name),
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradient Overlay at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.darkBg],
                ),
              ),
            ),
          ),

          // 3. Header Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar: Back button + Centered Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Streak + Weekly Calendar Card ───────────────────────────────────────────
class _StreakAndWeekCard extends StatelessWidget {
  const _StreakAndWeekCard({
    required this.habit,
    required this.detail,
    required this.color,
  });
  final TodayHabitModel habit;
  final HabitDetailState detail;
  final Color color;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  List<DateTime> get _currentWeekDays {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final days = _currentWeekDays;
    final today = DateTime.now();
    final todayStr = _fmt(today);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak row
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  Text(
                    '${habit.currentStreak} days',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.flameOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Week day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = days[i];
              final dateStr = _fmt(day);
              final isToday = dateStr == todayStr;
              final isDone = detail.weekCompletion[dateStr] == true;
              final isFuture = day.isAfter(today);

              return _WeekDayCell(
                label: _dayLabels[i],
                isDone: isDone,
                isToday: isToday,
                isFuture: isFuture,
                color: color,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.label,
    required this.isDone,
    required this.isToday,
    required this.isFuture,
    required this.color,
  });
  final String label;
  final bool isDone;
  final bool isToday;
  final bool isFuture;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? icon;

    if (isDone) {
      bgColor = AppColors.success.withOpacity(0.2);
      borderColor = AppColors.success.withOpacity(0.6);
      textColor = AppColors.success;
      icon = const Icon(Icons.check_rounded,
          size: 14, color: AppColors.success);
    } else if (isToday) {
      bgColor = color.withOpacity(0.15);
      borderColor = color;
      textColor = color;
      icon = null;
    } else if (isFuture) {
      bgColor = Colors.transparent;
      borderColor = AppColors.darkBorder.withOpacity(0.3);
      textColor = AppColors.darkTextSecondary.withOpacity(0.3);
      icon = null;
    } else {
      // Past, not done
      bgColor = AppColors.danger.withOpacity(0.08);
      borderColor = AppColors.danger.withOpacity(0.3);
      textColor = AppColors.darkTextSecondary;
      icon = null;
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: icon ??
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

// ─── Progress Card ────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.detail, required this.color});
  final HabitDetailState detail;
  final Color color;

  // Simple level from streak — every 10 days = 1 level
  int get _level => (detail.completedCount ~/ 10) + 1;
  String get _levelLabel {
    final lvl = _level;
    if (lvl <= 1) return 'Starting Today';
    if (lvl <= 2) return 'Getting Stronger';
    if (lvl <= 3) return 'Building Discipline';
    if (lvl <= 5) return 'Strong & Consistent';
    return 'Peak of Mastery';
  }

  @override
  Widget build(BuildContext context) {
    final pct = detail.completionPercentage;
    final progress = pct / 100.0;

    return Container(
      padding: const EdgeInsets.all(18),
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
                'Progress Journey',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              // Mountain icon + XP label
              Row(
                children: [
                  const Icon(Icons.terrain_rounded,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Level $_level',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _levelLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF2A263E),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.4), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$pct% today',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Card ───────────────────────────────────────────────────────────
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard(
      {required this.currentStreak, required this.color});
  final int currentStreak;
  final Color color;

  static const _milestones = [10, 20, 30, 50, 75, 100, 150, 200, 365];

  String get _nextMilestoneLabel {
    final next =
    _milestones.where((m) => m > currentStreak).toList();
    if (next.isEmpty) return 'All milestones unlocked 🏆';
    return 'Complete ${next.first} day streak';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Milestone',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nextMilestoneLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.darkTextSecondary, size: 20),
        ],
      ),
    );
  }
}

// ─── Subtask Tile ─────────────────────────────────────────────────────────────
class _SubtaskTile extends StatelessWidget {
  const _SubtaskTile({
    required this.subtask,
    required this.isDone,
    required this.color,
    required this.onTap,
  });
  final SubtaskModel subtask;
  final bool isDone;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color:
          isDone ? color.withOpacity(0.08) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? color.withOpacity(0.4)
                : AppColors.darkBorder,
          ),
        ),
        child: Row(
          children: [
            // Circle checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDone
                          ? AppColors.darkTextSecondary
                          : AppColors.darkTextPrimary,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.darkTextSecondary,
                    ),
                  ),
                  if (subtask.targetValue != null &&
                      subtask.unit != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${subtask.targetValue} ${subtask.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!subtask.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.darkTextSecondary),
                ),
              )
            else
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isDone
                    ? color
                    : AppColors.darkTextSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Mark Complete Button ─────────────────────────────────────────────────────
class _MarkCompleteButton extends StatelessWidget {
  const _MarkCompleteButton({
    required this.detail,
    required this.color,
    required this.onTap,
  });
  final HabitDetailState detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = detail.isCompleted;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        border:
        const Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: (isDone || detail.marking) ? null : onTap,
          icon: detail.marking
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : Icon(
            isDone
                ? Icons.check_circle_rounded
                : Icons.check_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            isDone ? 'Completed ✓' : 'Mark as Completed',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isDone ? AppColors.success.withOpacity(0.5) : color,
            disabledBackgroundColor: isDone
                ? AppColors.success.withOpacity(0.35)
                : color.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}