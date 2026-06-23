import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/habit_model.dart';
import '../models/remote/subtask_model.dart';
import '../repositories/onboarding_repository.dart';
import 'auth_provider.dart';

/// onboarding_provider.dart
/// Drives the 5-screen wizard: Welcome → Goal → Habits → Subtasks → Reminders.
/// Holds in-progress selections client-side; each "Continue" tap persists
/// that step to the server, then advances local state.

enum OnboardingSubmitStatus { idle, submitting, error }

class ReminderDraft {
  final String habitId;
  final List<String> times; // e.g. ['08:00']
  final List<int> days; // 0..6, defaults to every day

  const ReminderDraft({
    required this.habitId,
    this.times = const [],
    this.days = const [0, 1, 2, 3, 4, 5, 6],
  });

  ReminderDraft copyWith({List<String>? times, List<int>? days}) {
    return ReminderDraft(
      habitId: habitId,
      times: times ?? this.times,
      days: days ?? this.days,
    );
  }
}

class OnboardingState {
  final OnboardingSubmitStatus status;
  final String? errorMessage;

  final String? selectedGoal;
  final Set<String> selectedCategories;

  /// Real persisted Habit docs (with embedded Subtask docs) returned by
  /// POST /onboarding/habits — the source of truth for the subtasks screen.
  final List<HabitModel> habits;

  /// habitId -> set of enabled subtask ids, seeded from each habit's
  /// subtasks where isActive == true / isRequired == true by default.
  final Map<String, Set<String>> enabledSubtaskIds;

  /// habitId -> reminder draft, only for habits the user toggled "on".
  final Map<String, ReminderDraft> reminders;

  const OnboardingState({
    this.status = OnboardingSubmitStatus.idle,
    this.errorMessage,
    this.selectedGoal,
    this.selectedCategories = const {},
    this.habits = const [],
    this.enabledSubtaskIds = const {},
    this.reminders = const {},
  });

  OnboardingState copyWith({
    OnboardingSubmitStatus? status,
    String? errorMessage,
    String? selectedGoal,
    Set<String>? selectedCategories,
    List<HabitModel>? habits,
    Map<String, Set<String>>? enabledSubtaskIds,
    Map<String, ReminderDraft>? reminders,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      habits: habits ?? this.habits,
      enabledSubtaskIds: enabledSubtaskIds ?? this.enabledSubtaskIds,
      reminders: reminders ?? this.reminders,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._repository, this._ref) : super(const OnboardingState());

  final OnboardingRepository _repository;
  final Ref _ref;

  // ── Step 2: Purpose / Goal (single-select) ──────────────────────────────
  void selectGoal(String goal) {
    state = state.copyWith(selectedGoal: goal);
  }

  Future<bool> submitGoal() async {
    if (state.selectedGoal == null) {
      state = state.copyWith(
        status: OnboardingSubmitStatus.error,
        errorMessage: 'Pick what matters most to you to continue',
      );
      return false;
    }
    state = state.copyWith(status: OnboardingSubmitStatus.submitting, errorMessage: null);
    try {
      await _repository.setGoal(state.selectedGoal!);
      _ref.read(authProvider.notifier).updateUserOnboarding(
            onboardingStep: 2,
            selectedGoal: state.selectedGoal,
          );
      state = state.copyWith(status: OnboardingSubmitStatus.idle);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: OnboardingSubmitStatus.error, errorMessage: e.message);
      return false;
    }
  }

  // ── Step 3: Habits (multi-select) ────────────────────────────────────────
  void toggleCategory(String category) {
    final updated = Set<String>.from(state.selectedCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(selectedCategories: updated);
  }

  Future<bool> submitHabits() async {
    if (state.selectedCategories.isEmpty) {
      state = state.copyWith(
        status: OnboardingSubmitStatus.error,
        errorMessage: 'Pick at least one habit to continue',
      );
      return false;
    }
    state = state.copyWith(status: OnboardingSubmitStatus.submitting, errorMessage: null);
    try {
      final habits = await _repository.selectHabits(state.selectedCategories.toList());

      // Seed enabledSubtaskIds: required subtasks always on, optional ones
      // default to on too (matches the screenshot showing most pre-checked).
      final seeded = <String, Set<String>>{};
      for (final habit in habits) {
        seeded[habit.id] = habit.subtasks.map((s) => s.id).toSet();
      }

      _ref.read(authProvider.notifier).updateUserOnboarding(onboardingStep: 3);
      state = state.copyWith(
        status: OnboardingSubmitStatus.idle,
        habits: habits,
        enabledSubtaskIds: seeded,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: OnboardingSubmitStatus.error, errorMessage: e.message);
      return false;
    }
  }

  // ── Step 4: Subtasks (combined, all habits) ──────────────────────────────
  void toggleSubtask(String habitId, String subtaskId) {
    final current = Set<String>.from(state.enabledSubtaskIds[habitId] ?? {});
    if (current.contains(subtaskId)) {
      current.remove(subtaskId);
    } else {
      current.add(subtaskId);
    }
    final updated = Map<String, Set<String>>.from(state.enabledSubtaskIds);
    updated[habitId] = current;
    state = state.copyWith(enabledSubtaskIds: updated);
  }

  /// Adds a custom subtask locally for instant UI feedback. The actual
  /// persisted subtask is created server-side inside submitSubtasks() via
  /// the customSubtasks payload, then we refresh state with real ids.
  void addCustomSubtaskDraft(String habitId, String name) {
    final habit = state.habits.firstWhere((h) => h.id == habitId);
    final tempId = 'draft_${DateTime.now().millisecondsSinceEpoch}';
    final draftSubtask = SubtaskModel(
      id: tempId,
      habitId: habitId,
      userId: '',
      name: name,
      inputType: 'checkbox',
      isRequired: false,
      displayOrder: habit.subtasks.length,
      isActive: true,
    );
    final updatedHabits = state.habits.map((h) {
      if (h.id != habitId) return h;
      return h.copyWith(subtasks: [...h.subtasks, draftSubtask]);
    }).toList();

    final updatedEnabled = Map<String, Set<String>>.from(state.enabledSubtaskIds);
    updatedEnabled[habitId] = {...(updatedEnabled[habitId] ?? {}), tempId};

    state = state.copyWith(habits: updatedHabits, enabledSubtaskIds: updatedEnabled);
  }

  Future<bool> submitSubtasks() async {
    state = state.copyWith(status: OnboardingSubmitStatus.submitting, errorMessage: null);
    try {
      final payload = <Map<String, dynamic>>[];
      for (final habit in state.habits) {
        final enabled = state.enabledSubtaskIds[habit.id] ?? {};
        final customSubtasks = habit.subtasks
            .where((s) => s.id.startsWith('draft_') && enabled.contains(s.id))
            .map((s) => {
                  'name': s.name,
                  'inputType': s.inputType,
                  'isRequired': false,
                })
            .toList();
        final realEnabledIds = enabled.where((id) => !id.startsWith('draft_')).toList();

        payload.add({
          'habitId': habit.id,
          'enabledSubtaskIds': realEnabledIds,
          if (customSubtasks.isNotEmpty) 'customSubtasks': customSubtasks,
        });
      }

      await _repository.configureSubtasks(payload);
      _ref.read(authProvider.notifier).updateUserOnboarding(onboardingStep: 4);
      state = state.copyWith(status: OnboardingSubmitStatus.idle);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: OnboardingSubmitStatus.error, errorMessage: e.message);
      return false;
    }
  }

  // ── Step 5: Reminders ─────────────────────────────────────────────────
  void setReminderEnabled(String habitId, bool enabled) {
    final updated = Map<String, ReminderDraft>.from(state.reminders);
    if (enabled) {
      updated[habitId] = updated[habitId] ?? const ReminderDraft(habitId: '', times: ['08:00']).copyWith();
      updated[habitId] = ReminderDraft(habitId: habitId, times: const ['08:00']);
    } else {
      updated.remove(habitId);
    }
    state = state.copyWith(reminders: updated);
  }

  void setReminderTime(String habitId, String time) {
    final existing = state.reminders[habitId];
    if (existing == null) return;
    final updated = Map<String, ReminderDraft>.from(state.reminders);
    updated[habitId] = existing.copyWith(times: [time]);
    state = state.copyWith(reminders: updated);
  }

  Future<bool> submitRemindersAndComplete() async {
    state = state.copyWith(status: OnboardingSubmitStatus.submitting, errorMessage: null);
    try {
      final payload = state.reminders.values
          .map((r) => {'habitId': r.habitId, 'times': r.times, 'days': r.days})
          .toList();

      await _repository.setReminders(payload);
      await _repository.complete();

      _ref.read(authProvider.notifier).updateUserOnboarding(
            onboardingStep: 5,
            onboardingCompleted: true,
          );
      state = state.copyWith(status: OnboardingSubmitStatus.idle);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: OnboardingSubmitStatus.error, errorMessage: e.message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, status: OnboardingSubmitStatus.idle);
  }
}

final onboardingRepositoryProvider =
    Provider<OnboardingRepository>((ref) => OnboardingRepository());

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.watch(onboardingRepositoryProvider), ref);
});
