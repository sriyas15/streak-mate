/// habit_log_model.dart
/// Mirrors backend HabitLog schema. Returned by:
///   POST /habits/:habitId/logs
///   PATCH /habits/:habitId/logs/:date/subtasks/:subtaskId
///   POST /habits/:habitId/logs/:date/complete
class SubtaskResult {
  final String subtaskId;
  final bool isCompleted;
  final num? value;
  final DateTime? completedAt;

  const SubtaskResult({
    required this.subtaskId,
    required this.isCompleted,
    this.value,
    this.completedAt,
  });

  factory SubtaskResult.fromJson(Map<String, dynamic> json) {
    return SubtaskResult(
      subtaskId: (json['subtaskId'] as String?) ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      value: json['value'] as num?,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  SubtaskResult copyWith({bool? isCompleted, num? value}) {
    return SubtaskResult(
      subtaskId: subtaskId,
      isCompleted: isCompleted ?? this.isCompleted,
      value: value ?? this.value,
      completedAt: (isCompleted ?? this.isCompleted) ? DateTime.now() : null,
    );
  }
}

class HabitLogModel {
  final String id;
  final String habitId;
  final String userId;
  final String date; // "YYYY-MM-DD"
  final List<SubtaskResult> subtaskResults;
  final bool isCompleted;
  final int completionPercentage;
  final DateTime? completedAt;
  final bool loggedOffline;

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.subtaskResults,
    required this.isCompleted,
    required this.completionPercentage,
    this.completedAt,
    required this.loggedOffline,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['_id'] as String? ?? '',
      habitId: (json['habitId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      date: json['date'] as String? ?? '',
      subtaskResults: (json['subtaskResults'] as List?)
              ?.map((r) => SubtaskResult.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      completionPercentage: json['completionPercentage'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      loggedOffline: json['loggedOffline'] as bool? ?? false,
    );
  }

  HabitLogModel copyWith({
    List<SubtaskResult>? subtaskResults,
    bool? isCompleted,
    int? completionPercentage,
    DateTime? completedAt,
  }) {
    return HabitLogModel(
      id: id,
      habitId: habitId,
      userId: userId,
      date: date,
      subtaskResults: subtaskResults ?? this.subtaskResults,
      isCompleted: isCompleted ?? this.isCompleted,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      completedAt: completedAt ?? this.completedAt,
      loggedOffline: loggedOffline,
    );
  }
}

/// Combined model returned by GET /habits/today —
/// each habit doc has its todayLog attached.
class TodayHabitModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String category;
  final int currentStreak;
  final int bestStreak;
  final List<dynamic> subtasks; // populated separately if needed
  final HabitLogModel? todayLog;

  const TodayHabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.category,
    required this.currentStreak,
    required this.bestStreak,
    this.subtasks = const [],
    this.todayLog,
  });

  factory TodayHabitModel.fromJson(Map<String, dynamic> json) {
    final logJson = json['todayLog'];
    return TodayHabitModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '⭐',
      color: json['color'] as String? ?? '#1D9E75',
      category: json['category'] as String? ?? 'custom',
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      todayLog: logJson != null
          ? HabitLogModel.fromJson(logJson as Map<String, dynamic>)
          : null,
    );
  }

  bool get isCompleted => todayLog?.isCompleted ?? false;
  int get completionPercentage => todayLog?.completionPercentage ?? 0;

  TodayHabitModel copyWith({HabitLogModel? todayLog}) {
    return TodayHabitModel(
      id: id,
      name: name,
      icon: icon,
      color: color,
      category: category,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      subtasks: subtasks,
      todayLog: todayLog ?? this.todayLog,
    );
  }
}