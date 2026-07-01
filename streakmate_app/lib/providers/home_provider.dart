import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/habit_log_model.dart';
import '../models/remote/calendar_model.dart';
import '../repositories/home_repository.dart';
import 'calendar_provider.dart';

/// home_provider.dart
/// Drives the Home screen. Manages:
///  - Fetching today's habits (GET /habits/today)
///  - Creating logs on first tap (POST /habits/:id/logs)
///  - Toggling subtask completion (PATCH .../subtasks/:subtaskId)
///  - Optimistic UI updates so the screen feels instant
///  - Checking if yesterday was missed → prompts freeze/cheat day

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final List<TodayHabitModel> habits;
  final String? errorMessage;
  // habitId → true while an API call is in-flight for that habit
  final Set<String> loadingHabitIds;
  // non-null ("YYYY-MM-DD") if yesterday was missed and needs a prompt
  final String? missedYesterdayDate;

  const HomeState({
    this.status = HomeStatus.initial,
    this.habits = const [],
    this.errorMessage,
    this.loadingHabitIds = const {},
    this.missedYesterdayDate,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<TodayHabitModel>? habits,
    String? errorMessage,
    Set<String>? loadingHabitIds,
    String? missedYesterdayDate,
    bool clearMissedYesterday = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      errorMessage: errorMessage,
      loadingHabitIds: loadingHabitIds ?? this.loadingHabitIds,
      missedYesterdayDate: clearMissedYesterday
          ? null
          : (missedYesterdayDate ?? this.missedYesterdayDate),
    );
  }

  // ── Derived stats used by the UI ────────────────────────────────
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

  /// Called when user taps a subtask checkbox.
  /// Flow:
  ///  1. If no log exists yet, create one first (upsert).
  ///  2. Optimistically flip the subtask locally.
  ///  3. Fire PATCH to server.
  ///  4. Update state with real server response (recalculated percentages).
  Future<void> toggleSubtask({
    required String habitId,
    required String subtaskId,
    required bool currentValue,
  }) async {
    // Optimistic update
    _optimisticallyToggleSubtask(habitId, subtaskId, !currentValue);

    final loading = Set<String>.from(state.loadingHabitIds)..add(habitId);
    state = state.copyWith(loadingHabitIds: loading);

    try {
      // Ensure a log exists for today
      final habit = state.habits.firstWhere((h) => h.id == habitId);
      if (habit.todayLog == null) {
        final log = await _repository.createLog(habitId);
        _applyLog(habitId, log);
      }

      final updatedLog = await _repository.updateSubtaskResult(
        habitId: habitId,
        subtaskId: subtaskId,
        isCompleted: !currentValue,
      );
      _applyLog(habitId, updatedLog);
    } on ApiException catch (e) {
      debugPrint('[Home] toggleSubtask failed: ${e.message}');
      // Roll back optimistic update on failure
      _optimisticallyToggleSubtask(habitId, subtaskId, currentValue);
      state = state.copyWith(errorMessage: e.message);
    } finally {
      final done = Set<String>.from(state.loadingHabitIds)..remove(habitId);
      state = state.copyWith(loadingHabitIds: done);
    }
  }

  Future<void> refresh() => loadToday();

  void clearError() => state = state.copyWith(errorMessage: null);

  // ── Yesterday-missed check ──────────────────────────────────────
  Future<void> _checkYesterday() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final calNotifier = _ref.read(calendarProvider.notifier);
    var calState = _ref.read(calendarProvider);

    // Ensure the month containing yesterday is loaded
    final yesterdayMonth =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}';
    if (calState.month == null || calState.currentMonth != yesterdayMonth) {
      await calNotifier.loadMonth(yesterdayMonth);
      calState = _ref.read(calendarProvider);
    }

    final dayData = calState.month?.days[dateStr];

    if (dayData != null && dayData.status == DayStatus.missed) {
      state = state.copyWith(missedYesterdayDate: dateStr);
    }
  }

  void dismissMissedYesterdayPrompt() {
    state = state.copyWith(clearMissedYesterday: true);
  }

  // ── Private helpers ─────────────────────────────────────────────

  void _optimisticallyToggleSubtask(
      String habitId, String subtaskId, bool newValue) {
    final habits = state.habits.map((h) {
      if (h.id != habitId || h.todayLog == null) return h;
      final results = h.todayLog!.subtaskResults.map((r) {
        if (r.subtaskId != subtaskId) return r;
        return r.copyWith(isCompleted: newValue);
      }).toList();
      final completed = results.where((r) => r.isCompleted).length;
      final pct = results.isEmpty
          ? 0
          : ((completed / results.length) * 100).round();
      return h.copyWith(
        todayLog: h.todayLog!.copyWith(
          subtaskResults: results,
          completionPercentage: pct,
        ),
      );
    }).toList();
    state = state.copyWith(habits: habits);
  }

  void _applyLog(String habitId, HabitLogModel log) {
    final habits = state.habits.map((h) {
      if (h.id != habitId) return h;
      return h.copyWith(todayLog: log);
    }).toList();
    state = state.copyWith(habits: habits);
  }
}

final homeRepositoryProvider =
    Provider<HomeRepository>((ref) => HomeRepository());

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider), ref);
});