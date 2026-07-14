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

  const HomeState({
    this.status = HomeStatus.initial,
    this.habits = const [],
    this.errorMessage,
    this.loadingHabitIds = const {},
    this.missedYesterdayDate,
    this.yesterdayChecked = false,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<TodayHabitModel>? habits,
    String? errorMessage,
    Set<String>? loadingHabitIds,
    String? missedYesterdayDate,
    bool clearMissedYesterday = false,
    bool? yesterdayChecked,
  }) {
    return HomeState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      errorMessage: errorMessage,
      loadingHabitIds: loadingHabitIds ?? this.loadingHabitIds,
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
    final existingHabit = state.habits.firstWhere((h) => h.id == habitId);
    final needsLogCreation = existingHabit.todayLog == null; // capture BEFORE optimistic update

    _optimisticallyToggleSubtask(habitId, subtaskId, !currentValue, totalSubtasks);

    final loading = Set<String>.from(state.loadingHabitIds)..add(habitId);
    state = state.copyWith(loadingHabitIds: loading);

    try {
      if (needsLogCreation) {
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
      _optimisticallyToggleSubtask(habitId, subtaskId, currentValue, totalSubtasks);
      state = state.copyWith(errorMessage: e.message);
    } finally {
      final done = Set<String>.from(state.loadingHabitIds)..remove(habitId);
      state = state.copyWith(loadingHabitIds: done);
    }
  }

  Future<void> refresh() => loadToday();

  void clearError() => state = state.copyWith(errorMessage: null);

  Future<void> _checkYesterday() async {
    // Only check once per app session
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

    // Mark checked BEFORE setting missedYesterdayDate so subsequent
    // loadToday() calls skip this entirely
    state = state.copyWith(yesterdayChecked: true);

    if (dayData != null && dayData.status == DayStatus.missed) {
      state = state.copyWith(missedYesterdayDate: dateStr);
    }
  }

  void dismissMissedYesterdayPrompt() {
    state = state.copyWith(clearMissedYesterday: true);
  }

 void _optimisticallyToggleSubtask(
    String habitId, String subtaskId, bool newValue, int totalSubtasks) {
  final habits = state.habits.map((h) {
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