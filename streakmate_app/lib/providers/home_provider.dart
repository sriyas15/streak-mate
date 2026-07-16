import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/habit_log_model.dart';
import '../models/remote/calendar_model.dart';
import '../repositories/home_repository.dart';
import 'calendar_provider.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final List<TodayHabitModel> habits;
  final String? errorMessage;
  final Set<String> loadingHabitIds;
  final String? missedYesterdayDate;
  final bool yesterdayChecked;
  final Set<String> loadingSubtaskIds;

  const HomeState({
    this.status = HomeStatus.initial,
    this.habits = const [],
    this.errorMessage,
    this.loadingHabitIds = const {},
    this.loadingSubtaskIds = const {},
    this.missedYesterdayDate,
    this.yesterdayChecked = false,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<TodayHabitModel>? habits,
    String? errorMessage,
    Set<String>? loadingHabitIds,
    Set<String>? loadingSubtaskIds,
    String? missedYesterdayDate,
    bool clearMissedYesterday = false,
    bool? yesterdayChecked,
  }) {
    return HomeState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      errorMessage: errorMessage,
      loadingHabitIds: loadingHabitIds ?? this.loadingHabitIds,
      loadingSubtaskIds: loadingSubtaskIds ?? this.loadingSubtaskIds,
      missedYesterdayDate: clearMissedYesterday
          ? null
          : (missedYesterdayDate ?? this.missedYesterdayDate),
      yesterdayChecked: yesterdayChecked ?? this.yesterdayChecked,
    );
  }

  int get totalHabits => habits.length;
  int get completedHabits => habits.where((h) => h.isCompleted).length;
  double get overallProgress =>
      totalHabits == 0 ? 0 : completedHabits / totalHabits;
  bool get allDone => totalHabits > 0 && completedHabits == totalHabits;
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._repository, this._ref) : super(const HomeState());

  final HomeRepository _repository;
  final Ref _ref;

  Future<void> loadToday() async {
    state = state.copyWith(status: HomeStatus.loading, errorMessage: null);
    try {
      final habits = await _repository.getTodayHabits();
      state = state.copyWith(status: HomeStatus.loaded, habits: habits);
      await _checkYesterday();
    } on ApiException catch (e) {
      debugPrint('[Home] loadToday failed: ${e.message}');
      state = state.copyWith(status: HomeStatus.error, errorMessage: e.message);
    }
  }

  Future<void> toggleSubtask({
  required String habitId,
  required String subtaskId,
  required bool currentValue,
  required int totalSubtasks,
}) async {
  // ✅ Ignore tap if this specific subtask already has an API call in flight
  if (state.loadingSubtaskIds.contains(subtaskId)) return;

  final existingHabit = state.habits.firstWhere((h) => h.id == habitId);
  final needsLogCreation = existingHabit.todayLog == null;

  final optimisticHabits = _buildOptimisticHabits(
    habitId, subtaskId, !currentValue, totalSubtasks,
  );
  final loading = Set<String>.from(state.loadingHabitIds)..add(habitId);
  final loadingSubtasks = Set<String>.from(state.loadingSubtaskIds)..add(subtaskId); // ✅
  state = state.copyWith(
    habits: optimisticHabits,
    loadingHabitIds: loading,
    loadingSubtaskIds: loadingSubtasks, // ✅
  );

  try {
    if (needsLogCreation) {
      await _repository.createLog(habitId);
    }
    final updatedLog = await _repository.updateSubtaskResult(
      habitId: habitId,
      subtaskId: subtaskId,
      isCompleted: !currentValue,
    );
    _applyLog(habitId, updatedLog, subtaskId);
  } on ApiException catch (e) {
    debugPrint('[Home] toggleSubtask failed: ${e.message}');
    final revertHabits = _buildOptimisticHabits(
      habitId, subtaskId, currentValue, totalSubtasks,
    );
    state = state.copyWith(habits: revertHabits, errorMessage: e.message);
  } finally {
    final done = Set<String>.from(state.loadingHabitIds)..remove(habitId);
    final doneSubtasks = Set<String>.from(state.loadingSubtaskIds)..remove(subtaskId); // ✅
    state = state.copyWith(
      loadingHabitIds: done,
      loadingSubtaskIds: doneSubtasks, // ✅
    );
  }
}

  Future<void> refresh() => loadToday();

  void clearError() => state = state.copyWith(errorMessage: null);

  Future<void> _checkYesterday() async {
    if (state.yesterdayChecked) return;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final calNotifier = _ref.read(calendarProvider.notifier);
    var calState = _ref.read(calendarProvider);

    final yesterdayMonth =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}';
    if (calState.month == null || calState.currentMonth != yesterdayMonth) {
      await calNotifier.loadMonth(yesterdayMonth);
      calState = _ref.read(calendarProvider);
    }

    final dayData = calState.month?.days[dateStr];

    state = state.copyWith(yesterdayChecked: true);

    if (dayData != null && dayData.status == DayStatus.missed) {
      state = state.copyWith(missedYesterdayDate: dateStr);
    }
  }

  void dismissMissedYesterdayPrompt() {
    state = state.copyWith(clearMissedYesterday: true);
  }

  /// Returns a new habits list with the subtask toggled — does NOT write state.
  /// Caller is responsible for writing state (allows batching with other fields).
  List<TodayHabitModel> _buildOptimisticHabits(
    String habitId,
    String subtaskId,
    bool newValue,
    int totalSubtasks,
  ) {
    return state.habits.map((h) {
      if (h.id != habitId) return h;

      final existingResults = h.todayLog?.subtaskResults ?? [];
      final hasResult = existingResults.any((r) => r.subtaskId == subtaskId);

      final results = hasResult
          ? existingResults.map((r) {
              if (r.subtaskId != subtaskId) return r;
              return r.copyWith(isCompleted: newValue);
            }).toList()
          : [
              ...existingResults,
              SubtaskResult(subtaskId: subtaskId, isCompleted: newValue),
            ];

      final completed = results.where((r) => r.isCompleted).length;
      final pct = totalSubtasks == 0
          ? 0
          : ((completed / totalSubtasks) * 100).round();
      final allDone = totalSubtasks > 0 && completed == totalSubtasks;

      final baseLog = h.todayLog ??
          HabitLogModel(
            id: '',
            habitId: habitId,
            userId: '',
            date: '',
            subtaskResults: const [],
            isCompleted: false,
            completionPercentage: 0,
            loggedOffline: false,
          );

      return h.copyWith(
        todayLog: baseLog.copyWith(
          subtaskResults: results,
          completionPercentage: pct,
          isCompleted: allDone,
        ),
      );
    }).toList();
  }

  /// Merges server log into current state.
  /// Server result wins for the updated subtask; optimistic state kept for the rest.
  void _applyLog(String habitId, HabitLogModel updatedLog, String subtaskId) {
  final habits = state.habits.map((h) {
    if (h.id != habitId) return h;

    final existingResults = h.todayLog?.subtaskResults ?? [];

    // ✅ Only update the specific subtask from server, keep everything else as-is
    final serverResult = updatedLog.subtaskResults.firstWhere(
      (r) => r.subtaskId == subtaskId,
      orElse: () => SubtaskResult(subtaskId: subtaskId, isCompleted: true),
    );

    final mergedResults = existingResults.map((r) {
      if (r.subtaskId != subtaskId) return r; // ✅ keep optimistic state
      return serverResult;                     // ✅ server wins only for this subtask
    }).toList();

    // Use server's completionPercentage and isCompleted only if no other
    // subtasks are still in-flight, otherwise keep optimistic values
    final hasOtherInFlight = state.loadingSubtaskIds
        .where((id) => id != subtaskId)
        .isNotEmpty;

    final mergedLog = updatedLog.copyWith(
      subtaskResults: mergedResults,
      // ✅ if other subtasks are still being toggled, trust our optimistic pct
      completionPercentage: hasOtherInFlight
          ? h.todayLog?.completionPercentage ?? updatedLog.completionPercentage
          : updatedLog.completionPercentage,
      isCompleted: hasOtherInFlight
          ? h.todayLog?.isCompleted ?? updatedLog.isCompleted
          : updatedLog.isCompleted,
    );

    return h.copyWith(todayLog: mergedLog);
  }).toList();

  state = state.copyWith(habits: habits);
}

  void removeHabit(String habitId) {
    state = state.copyWith(
      habits: state.habits.where((h) => h.id != habitId).toList(),
    );
  }
}

final homeRepositoryProvider =
    Provider<HomeRepository>((ref) => HomeRepository());

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider), ref);
});