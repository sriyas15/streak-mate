import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/habit_model.dart';
import '../repositories/habit_repository.dart';

class AddHabitState {
  // Step 1 — template selection
  final String? selectedCategory;
  final String? selectedName;
  final String? selectedIcon;
  final String? selectedColor;

  // Step 2 — customisation
  final String customName;
  final String? description;
  final String frequency; // daily | custom
  final List<int> activeDays;

  // Submit state
  final bool saving;
  final String? error;
  final HabitModel? createdHabit;

  const AddHabitState({
    this.selectedCategory,
    this.selectedName,
    this.selectedIcon,
    this.selectedColor,
    this.customName = '',
    this.description,
    this.frequency = 'daily',
    this.activeDays = const [0, 1, 2, 3, 4, 5, 6],
    this.saving = false,
    this.error,
    this.createdHabit,
  });

  AddHabitState copyWith({
    String? selectedCategory,
    String? selectedName,
    String? selectedIcon,
    String? selectedColor,
    String? customName,
    String? description,
    String? frequency,
    List<int>? activeDays,
    bool? saving,
    String? error,
    HabitModel? createdHabit,
  }) =>
      AddHabitState(
        selectedCategory: selectedCategory ?? this.selectedCategory,
        selectedName: selectedName ?? this.selectedName,
        selectedIcon: selectedIcon ?? this.selectedIcon,
        selectedColor: selectedColor ?? this.selectedColor,
        customName: customName ?? this.customName,
        description: description ?? this.description,
        frequency: frequency ?? this.frequency,
        activeDays: activeDays ?? this.activeDays,
        saving: saving ?? this.saving,
        error: error,
        createdHabit: createdHabit ?? this.createdHabit,
      );

  bool get isTemplateSelected => selectedCategory != null;

  String get finalName =>
      customName.trim().isNotEmpty ? customName.trim() : (selectedName ?? '');
}

class AddHabitNotifier extends StateNotifier<AddHabitState> {
  AddHabitNotifier(this._repo) : super(const AddHabitState());
  final HabitRepository _repo;

  void selectTemplate({
    required String category,
    required String name,
    required String icon,
    required String color,
  }) {
    state = state.copyWith(
      selectedCategory: category,
      selectedName: name,
      selectedIcon: icon,
      selectedColor: color,
      customName: name, // pre-fill the name field
    );
  }

  void setName(String name) => state = state.copyWith(customName: name);
  void setDescription(String desc) =>
      state = state.copyWith(description: desc);
  void setFrequency(String freq) =>
      state = state.copyWith(frequency: freq);

  void toggleDay(int day) {
    final days = List<int>.from(state.activeDays);
    if (days.contains(day)) {
      if (days.length > 1) days.remove(day); // keep at least one day
    } else {
      days.add(day);
      days.sort();
    }
    state = state.copyWith(activeDays: days);
  }

  Future<bool> save() async {
    if (state.selectedCategory == null) {
      state = state.copyWith(error: 'Please select a habit category');
      return false;
    }
    if (state.finalName.isEmpty) {
      state = state.copyWith(error: 'Please enter a habit name');
      return false;
    }

    state = state.copyWith(saving: true, error: null);
    try {
      final habit = await _repo.createHabit(
        name: state.finalName,
        category: state.selectedCategory!,
        icon: state.selectedIcon ?? '⭐',
        color: state.selectedColor ?? '#1D9E75',
        description: state.description,
        frequency: state.frequency,
        activeDays: state.activeDays,
      );
      state = state.copyWith(saving: false, createdHabit: habit);
      debugPrint('[AddHabit] Created: ${habit.name} (${habit.id})');
      return true;
    } on ApiException catch (e) {
      debugPrint('[AddHabit] error: ${e.message}');
      state = state.copyWith(saving: false, error: e.message);
      return false;
    }
  }

  void reset() => state = const AddHabitState();
  void clearError() => state = state.copyWith(error: null);
}

final habitRepositoryProvider =
    Provider<HabitRepository>((ref) => HabitRepository());

final addHabitProvider =
    StateNotifierProvider.autoDispose<AddHabitNotifier, AddHabitState>(
        (ref) => AddHabitNotifier(ref.watch(habitRepositoryProvider)));
