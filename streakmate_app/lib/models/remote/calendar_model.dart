/// calendar_model.dart
/// Mirrors calendarService.getMonth and getDay response shapes.

// ── Day status enum (mirrors DAY_STATUS from constants.js) ──────────────────
enum DayStatus {
  completed,
  partial,
  missed,
  freeze,
  cheat,
  today,
  future,
  none;

  static DayStatus fromString(String? s) {
    switch (s) {
      case 'completed': return DayStatus.completed;
      case 'partial':   return DayStatus.partial;
      case 'missed':    return DayStatus.missed;
      case 'freeze':    return DayStatus.freeze;
      case 'cheat':     return DayStatus.cheat;
      case 'today':     return DayStatus.today;
      case 'future':    return DayStatus.future;
      default:          return DayStatus.none;
    }
  }
}

// ── Habit summary inside a calendar day ─────────────────────────────────────
class CalendarHabitSummary {
  final String habitId;
  final String? name;
  final String? icon;
  final bool isCompleted;
  final int completionPercentage;

  const CalendarHabitSummary({
    required this.habitId,
    this.name,
    this.icon,
    required this.isCompleted,
    required this.completionPercentage,
  });

  factory CalendarHabitSummary.fromJson(Map<String, dynamic> json) =>
      CalendarHabitSummary(
        habitId: (json['habitId'] ?? '').toString(),
        name: json['name'] as String?,
        icon: json['icon'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completionPercentage: json['completionPercentage'] as int? ?? 0,
      );
}

// ── Single day entry from getMonth ──────────────────────────────────────────
class CalendarDay {
  final String date;
  final DayStatus status;
  final int productivityScore;
  final int completedHabits;
  final int totalHabits;
  final List<CalendarHabitSummary> habits;

  const CalendarDay({
    required this.date,
    required this.status,
    required this.productivityScore,
    required this.completedHabits,
    required this.totalHabits,
    this.habits = const [],
  });

  factory CalendarDay.fromJson(String date, Map<String, dynamic> json) =>
      CalendarDay(
        date: date,
        status: DayStatus.fromString(json['status'] as String?),
        productivityScore: json['productivityScore'] as int? ?? 0,
        completedHabits: json['completedHabits'] as int? ?? 0,
        totalHabits: json['totalHabits'] as int? ?? 0,
        habits: (json['habits'] as List?)
                ?.map((h) => CalendarHabitSummary.fromJson(
                    h as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

// ── Full month response ──────────────────────────────────────────────────────
class CalendarMonth {
  final String month; // "2024-06"
  final String from;  // "2024-06-01"
  final String to;    // "2024-06-30"
  final Map<String, CalendarDay> days; // date string → CalendarDay

  const CalendarMonth({
    required this.month,
    required this.from,
    required this.to,
    required this.days,
  });

  factory CalendarMonth.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as Map<String, dynamic>? ?? {};
    final days = rawDays.map((date, dayData) => MapEntry(
          date,
          CalendarDay.fromJson(date, dayData as Map<String, dynamic>),
        ));
    return CalendarMonth(
      month: json['month'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      days: days,
    );
  }
}

// ── Day detail response from getDay ─────────────────────────────────────────
class CalendarDayDetail {
  final String date;
  final Map<String, dynamic>? dayLog;
  final List<CalendarDayHabit> habits;

  const CalendarDayDetail({
    required this.date,
    this.dayLog,
    this.habits = const [],
  });

  factory CalendarDayDetail.fromJson(Map<String, dynamic> json) =>
      CalendarDayDetail(
        date: json['date'] as String? ?? '',
        dayLog: json['dayLog'] as Map<String, dynamic>?,
        habits: (json['habits'] as List?)
                ?.map((h) => CalendarDayHabit.fromJson(
                    h as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  bool get isProductiveDay =>
      dayLog?['isProductiveDay'] as bool? ?? false;
  int get productivityScore =>
      dayLog?['productivityScore'] as int? ?? 0;
}

class CalendarDayHabit {
  final String habitId;
  final String? habitName;
  final String? habitIcon;
  final String? habitColor;
  final String? category;
  final bool isCompleted;
  final int completionPercentage;

  const CalendarDayHabit({
    required this.habitId,
    this.habitName,
    this.habitIcon,
    this.habitColor,
    this.category,
    required this.isCompleted,
    required this.completionPercentage,
  });

  factory CalendarDayHabit.fromJson(Map<String, dynamic> json) =>
      CalendarDayHabit(
        habitId: (json['habitId'] ?? json['_id'] ?? '').toString(),
        habitName: json['habitName'] as String?,
        habitIcon: json['habitIcon'] as String?,
        habitColor: json['habitColor'] as String?,
        category: json['category'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completionPercentage:
            json['completionPercentage'] as int? ?? 0,
      );
}