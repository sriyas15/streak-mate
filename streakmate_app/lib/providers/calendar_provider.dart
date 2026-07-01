import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/calendar_model.dart';
import '../repositories/calendar_repository.dart';

class CalendarState {
  final bool loadingMonth;
  final bool loadingDay;
  final CalendarMonth? month;
  final CalendarDayDetail? selectedDay;
  final String currentMonth; // "YYYY-MM"
  final String? error;

  const CalendarState({
    this.loadingMonth = false,
    this.loadingDay = false,
    this.month,
    this.selectedDay,
    required this.currentMonth,
    this.error,
  });

  CalendarState copyWith({
    bool? loadingMonth,
    bool? loadingDay,
    CalendarMonth? month,
    CalendarDayDetail? selectedDay,
    String? currentMonth,
    String? error,
  }) =>
      CalendarState(
        loadingMonth: loadingMonth ?? this.loadingMonth,
        loadingDay: loadingDay ?? this.loadingDay,
        month: month ?? this.month,
        selectedDay: selectedDay ?? this.selectedDay,
        currentMonth: currentMonth ?? this.currentMonth,
        error: error,
      );
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier(this._repo)
      : super(CalendarState(currentMonth: _thisMonth())) {
    loadMonth(_thisMonth());
  }

  final CalendarRepository _repo;

  static String _thisMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> loadMonth(String month) async {
    state = state.copyWith(loadingMonth: true, error: null, currentMonth: month);
    try {
      final result = await _repo.getMonth(month);
      // DEBUG — remove after fixing
      debugPrint('[Calendar] month=${result.month} days count=${result.days.length}');
      if (result.days.isNotEmpty) {
        final sample = result.days.entries.take(5);
        for (final e in sample) {
          debugPrint('[Calendar] date=${e.key} status=${e.value.status} completed=${e.value.completedHabits}/${e.value.totalHabits} score=${e.value.productivityScore}');
        }
      }
      state = state.copyWith(loadingMonth: false, month: result);
    } on ApiException catch (e) {
      debugPrint('[Calendar] loadMonth error: ${e.message}');
      state = state.copyWith(loadingMonth: false, error: e.message);
    }
  }

  Future<void> loadDay(String date) async {
    state = state.copyWith(loadingDay: true, error: null);
    try {
      final result = await _repo.getDay(date);
      state = state.copyWith(loadingDay: false, selectedDay: result);
    } on ApiException catch (e) {
      debugPrint('[Calendar] loadDay error: ${e.message}');
      state = state.copyWith(loadingDay: false, error: e.message);
    }
  }

  void handleSocketUpdate(dynamic data) {
    final date = data['date'] as String?;
    if (date == null) return;

    final month = date.substring(0, 7);

    // If this month is currently displayed, reload it
    if (state.currentMonth == month) {
      loadMonth(month);
    }
  }

  void goToPreviousMonth() {
    final parts = state.currentMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final prev = month == 1
        ? DateTime(year - 1, 12)
        : DateTime(year, month - 1);
    loadMonth(
        '${prev.year}-${prev.month.toString().padLeft(2, '0')}');
  }

  void goToNextMonth() {
    final parts = state.currentMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final next = month == 12
        ? DateTime(year + 1, 1)
        : DateTime(year, month + 1);
    // Don't allow future months beyond current
    final now = DateTime.now();
    final nextMonth =
        '${next.year}-${next.month.toString().padLeft(2, '0')}';
    final thisMonth = _thisMonth();
    if (nextMonth.compareTo(thisMonth) <= 0) {
      loadMonth(nextMonth);
    }
  }

  void clearSelectedDay() =>
      state = state.copyWith(selectedDay: null);

  void clearError() => state = state.copyWith(error: null);
}

final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => CalendarRepository());

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(ref.watch(calendarRepositoryProvider));
});