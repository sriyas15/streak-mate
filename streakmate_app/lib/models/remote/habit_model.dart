import 'subtask_model.dart';

/// habit_model.dart
/// Mirrors backend habitSchema. During onboarding, onboardingService
/// .selectHabits returns each created habit with its `subtasks` array
/// populated client-side (habits.push({ ...habit, subtasks: subtaskDocs })),
/// so this model accepts an embedded `subtasks` list even though the
/// Habit collection itself only stores a single subtasks ObjectId ref
/// in some places — the onboarding response shape is the one that
/// matters for this screen.
class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String icon;
  final String color;
  final String? description;
  final String frequency; // daily | custom
  final List<int> activeDays;
  final String startDate;
  final String completionRule; // all_required | percentage | user_defined
  final int completionThreshold;
  final int currentStreak;
  final int bestStreak;
  final bool reminderEnabled;
  final List<String> reminderTimes;
  final List<int> reminderDays;
  final int displayOrder;
  final bool isActive;
  final bool isCustom;
  final List<SubtaskModel> subtasks;

  const HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    this.description,
    required this.frequency,
    required this.activeDays,
    required this.startDate,
    required this.completionRule,
    required this.completionThreshold,
    required this.currentStreak,
    required this.bestStreak,
    required this.reminderEnabled,
    required this.reminderTimes,
    required this.reminderDays,
    required this.displayOrder,
    required this.isActive,
    required this.isCustom,
    this.subtasks = const [],
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String? ?? '⭐',
      color: json['color'] as String? ?? '#1D9E75',
      description: json['description'] as String?,
      frequency: json['frequency'] as String? ?? 'daily',
      activeDays: (json['activeDays'] as List?)?.map((e) => e as int).toList() ??
          const [0, 1, 2, 3, 4, 5, 6],
      startDate: json['startDate'] as String? ?? '',
      completionRule: json['completionRule'] as String? ?? 'all_required',
      completionThreshold: json['completionThreshold'] as int? ?? 100,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderTimes: (json['reminderTimes'] as List?)?.map((e) => e as String).toList() ?? const [],
      reminderDays: (json['reminderDays'] as List?)?.map((e) => e as int).toList() ??
          const [0, 1, 2, 3, 4, 5, 6],
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
      subtasks: (json['subtasks'] as List?)
              ?.map((s) => SubtaskModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  HabitModel copyWith({
    List<SubtaskModel>? subtasks,
    bool? reminderEnabled,
    List<String>? reminderTimes,
    List<int>? reminderDays,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      name: name,
      category: category,
      icon: icon,
      color: color,
      description: description,
      frequency: frequency,
      activeDays: activeDays,
      startDate: startDate,
      completionRule: completionRule,
      completionThreshold: completionThreshold,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      reminderDays: reminderDays ?? this.reminderDays,
      displayOrder: displayOrder,
      isActive: isActive,
      isCustom: isCustom,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
