/// analytics_model.dart
/// Mirrors all analyticsService response shapes.

// ── Overview (GET /analytics/overview?period=week|month) ────────────────────
class AnalyticsOverview {
  final String period;
  final int totalDays;
  final int productiveDays;
  final int missedDays;
  final double consistencyRate; // 0-100
  final int currentStreak;
  final int bestStreak;
  final int totalHabitsCompleted;
  final int totalHabitsScheduled;
  final double completionRate; // 0-100
  final List<DailyActivity> dailyActivity;

  const AnalyticsOverview({
    required this.period,
    required this.totalDays,
    required this.productiveDays,
    required this.missedDays,
    required this.consistencyRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalHabitsCompleted,
    required this.totalHabitsScheduled,
    required this.completionRate,
    required this.dailyActivity,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      AnalyticsOverview(
        period: json['period'] as String? ?? 'week',
        totalDays: json['totalDays'] as int? ?? 0,
        productiveDays: json['productiveDays'] as int? ?? 0,
        missedDays: json['missedDays'] as int? ?? 0,
        consistencyRate: (json['consistencyRate'] as num?)?.toDouble() ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        totalHabitsCompleted: json['totalHabitsCompleted'] as int? ?? 0,
        totalHabitsScheduled: json['totalHabitsScheduled'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
        dailyActivity: (json['dailyActivity'] as List?)
                ?.map((d) =>
                    DailyActivity.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class DailyActivity {
  final String date; // "YYYY-MM-DD"
  final String dayLabel; // "Mon", "Tue" etc
  final bool isProductive;
  final int completedHabits;
  final int totalHabits;
  final double completionRate; // 0-100

  const DailyActivity({
    required this.date,
    required this.dayLabel,
    required this.isProductive,
    required this.completedHabits,
    required this.totalHabits,
    required this.completionRate,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) =>
      DailyActivity(
        date: json['date'] as String? ?? '',
        dayLabel: json['dayLabel'] as String? ?? _dayLabel(json['date'] as String?),
        isProductive: json['isProductive'] as bool? ?? false,
        completedHabits: json['completedHabits'] as int? ?? 0,
        totalHabits: json['totalHabits'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      );

  static String _dayLabel(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[dt.weekday % 7];
    } catch (_) {
      return '';
    }
  }
}

// ── Category performance ─────────────────────────────────────────────────────
class CategoryPerformance {
  final String category;
  final String name;
  final String icon;
  final String color;
  final int completedDays;
  final int totalDays;
  final double rate; // 0-100

  const CategoryPerformance({
    required this.category,
    required this.name,
    required this.icon,
    required this.color,
    required this.completedDays,
    required this.totalDays,
    required this.rate,
  });

  factory CategoryPerformance.fromJson(Map<String, dynamic> json) =>
      CategoryPerformance(
        category: json['category'] as String? ?? '',
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '⭐',
        color: json['color'] as String? ?? '#1D9E75',
        completedDays: json['completedDays'] as int? ?? 0,
        totalDays: json['totalDays'] as int? ?? 0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
      );
}

// ── Weekly summary ───────────────────────────────────────────────────────────
class WeeklySummary {
  final String weekLabel;
  final int productiveDays;
  final int totalDays;
  final double consistencyRate;
  final int habitsCompleted;
  final int bestDay; // 0-6 weekday
  final String motivationalMessage;

  const WeeklySummary({
    required this.weekLabel,
    required this.productiveDays,
    required this.totalDays,
    required this.consistencyRate,
    required this.habitsCompleted,
    required this.bestDay,
    required this.motivationalMessage,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) =>
      WeeklySummary(
        weekLabel: json['weekLabel'] as String? ?? 'This Week',
        productiveDays: json['productiveDays'] as int? ?? 0,
        totalDays: json['totalDays'] as int? ?? 7,
        consistencyRate: (json['consistencyRate'] as num?)?.toDouble() ?? 0,
        habitsCompleted: json['habitsCompleted'] as int? ?? 0,
        bestDay: json['bestDay'] as int? ?? 0,
        motivationalMessage: json['motivationalMessage'] as String? ?? '',
      );
}

// ── Heatmap ──────────────────────────────────────────────────────────────────
class HeatmapDay {
  final String date;
  final int value; // 0 = none, 1 = partial, 2 = completed
  final bool isProductive;

  const HeatmapDay({
    required this.date,
    required this.value,
    required this.isProductive,
  });

  factory HeatmapDay.fromJson(String date, Map<String, dynamic> json) =>
      HeatmapDay(
        date: date,
        value: json['value'] as int? ??
            (json['isProductive'] == true ? 2 : 0),
        isProductive: json['isProductive'] as bool? ?? false,
      );
}

// ── Insights ─────────────────────────────────────────────────────────────────
class AnalyticsInsight {
  final String type; // 'strength' | 'weakness' | 'tip'
  final String title;
  final String description;
  final String? habitName;
  final String? icon;

  const AnalyticsInsight({
    required this.type,
    required this.title,
    required this.description,
    this.habitName,
    this.icon,
  });

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) =>
      AnalyticsInsight(
        type: json['type'] as String? ?? 'tip',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        habitName: json['habitName'] as String?,
        icon: json['icon'] as String?,
      );
}