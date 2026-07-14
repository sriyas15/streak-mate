import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/analytics_model.dart';
import '../../../models/remote/calendar_model.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/calendar_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).loadAll();
      // Load current month calendar data for the chart
      final now = DateTime.now();
      final month =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref.read(calendarProvider.notifier).loadMonth(month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final calState = ref.watch(calendarProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<AnalyticsState>(analyticsProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.danger),
        );
        ref.read(analyticsProvider.notifier).clearError();
      }
    });

    // Build chart spots from calendar month data
    final chartSpots = _buildChartSpots(calState.month);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Insights',
            style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                _PeriodChip(
                  label: 'Week',
                  selected: state.period == AnalyticsPeriod.week,
                  onTap: () => ref
                      .read(analyticsProvider.notifier)
                      .setPeriod(AnalyticsPeriod.week),
                ),
                _PeriodChip(
                  label: 'Month',
                  selected: state.period == AnalyticsPeriod.month,
                  onTap: () => ref
                      .read(analyticsProvider.notifier)
                      .setPeriod(AnalyticsPeriod.month),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.flameOrange))
          : RefreshIndicator(
              color: AppColors.flameOrange,
              backgroundColor: AppColors.darkSurface,
              onRefresh: () =>
                  ref.read(analyticsProvider.notifier).loadAll(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // ── Motivational heading ──────────────────────
                  _MotivationalHeading(state: state),
                  const SizedBox(height: 20),

                  // ── Consistency gauge + stat cards ────────────
                  _ConsistencyRow(overview: state.overview),
                  const SizedBox(height: 20),

                  // ── Line chart from calendar data ─────────────
                  if (chartSpots.isNotEmpty) ...[
                    _ChartSection(
                      spots: chartSpots,
                      calMonth: calState.month,
                      period: state.period,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Category performance ──────────────────────
                  if (state.categories.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Category Performance',
                      subtitle: state.period == AnalyticsPeriod.week
                          ? 'This week'
                          : 'This month',
                    ),
                    const SizedBox(height: 12),
                    ...state.categories
                        .map((c) => _CategoryRow(category: c)),
                    const SizedBox(height: 20),
                  ],

                  // ── Heatmap ───────────────────────────────────
                  if (state.heatmap.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Activity Heatmap',
                      subtitle: '${DateTime.now().year}',
                    ),
                    const SizedBox(height: 12),
                    _HeatmapGrid(days: state.heatmap),
                    const SizedBox(height: 20),
                  ],

                  // ── Focus areas ───────────────────────────────
                  if (state.insights.isNotEmpty) ...[
                    const _SectionHeader(
                      title: 'Focus Areas',
                      subtitle: 'See where you can improve',
                    ),
                    const SizedBox(height: 12),
                    ...state.insights
                        .map((i) => _InsightTile(insight: i)),
                  ],
                ],
              ),
            ),
    );
  }

  /// Converts CalendarMonth days → LineChart FlSpots.
  /// x = day number in month, y = completionPercentage (0–100).
  List<FlSpot> _buildChartSpots(CalendarMonth? month) {
    if (month == null) return [];
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (final entry in month.days.entries) {
      try {
        final date = DateTime.parse(entry.key);
        // Only include days up to today
        if (date.isAfter(now)) continue;
        if (date.month != now.month || date.year != now.year) continue;
        final day = entry.value;
        double y;
        switch (day.status) {
          case DayStatus.completed:
            y = 100;
            break;
          case DayStatus.partial:
            y = day.productivityScore.toDouble().clamp(10, 90);
            break;
          case DayStatus.missed:
            y = 0;
            break;
          case DayStatus.freeze:
          case DayStatus.cheat:
            y = 50;
            break;
          default:
            continue;
        }
        spots.add(FlSpot(date.day.toDouble(), y));
      } catch (_) {}
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }
}

// ── Motivational heading ──────────────────────────────────────────────────────
class _MotivationalHeading extends StatelessWidget {
  const _MotivationalHeading({required this.state});
  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.motivationalHeading,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          state.motivationalSubtitle,
          style: const TextStyle(
              fontSize: 14, color: AppColors.darkTextSecondary),
        ),
      ],
    );
  }
}

// ── Consistency gauge + stat cards ────────────────────────────────────────────
class _ConsistencyRow extends StatelessWidget {
  const _ConsistencyRow({required this.overview});
  final AnalyticsOverview? overview;

  @override
  Widget build(BuildContext context) {
    final rate = overview?.consistencyRate ?? 0;
    final streak = overview?.bestStreak ?? 0;
    final completed = overview?.totalHabitsCompleted ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular consistency gauge
        _CircularGauge(
          percentage: rate,
          label: 'Consistency',
        ),
        const SizedBox(width: 14),
        // Two stat cards stacked
        Expanded(
          child: Column(
            children: [
              _SmallStatCard(
                emoji: '🔥',
                value: '$streak',
                label: 'Best Streak',
                color: AppColors.flameOrange,
              ),
              const SizedBox(height: 10),
              _SmallStatCard(
                emoji: '✅',
                value: '$completed',
                label: 'Completed',
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Circular gauge ────────────────────────────────────────────────────────────
class _CircularGauge extends StatelessWidget {
  const _CircularGauge({
    required this.percentage,
    required this.label,
  });
  final double percentage;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // PieChart as donut gauge
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 44,
              sections: [
                PieChartSectionData(
                  value: percentage == 0 ? 0.001 : percentage,
                  color: AppColors.prayerPurple,
                  radius: 16,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: percentage >= 100 ? 0.001 : (100 - percentage),
                  color: AppColors.darkBorder,
                  radius: 14,
                  showTitle: false,
                ),
              ],
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkTextPrimary),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });
  final String emoji;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.darkTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chart section ─────────────────────────────────────────────────────────────
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.spots,
    required this.calMonth,
    required this.period,
  });
  final List<FlSpot> spots;
  final CalendarMonth? calMonth;
  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = period == AnalyticsPeriod.week
        ? 'This Week'
        : '${_monthName(now.month)} ${now.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Activity',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.darkBorder.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.darkTextSecondary),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: spots.length > 15 ? 5 : 2,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.darkTextSecondary),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.flameOrange,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: spot.y >= 100
                            ? AppColors.success
                            : spot.y == 0
                                ? AppColors.danger
                                : AppColors.flameOrange,
                        strokeWidth: 1.5,
                        strokeColor: AppColors.darkBg,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.flameOrange.withOpacity(0.25),
                          AppColors.flameOrange.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.darkSurfaceElevated,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              'Day ${s.x.toInt()}\n${s.y.round()}%',
                              const TextStyle(
                                  color: AppColors.flameOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m];
  }
}

// ── Category row ──────────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});
  final CategoryPerformance category;

  @override
  Widget build(BuildContext context) {
    final color = Color(
        int.parse(category.color.replaceFirst('#', '0xFF')));
    final rate = (category.rate / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary)),
                    Text('${category.rate.round()}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 5,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${category.completedDays}/${category.totalDays} days',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Heatmap ───────────────────────────────────────────────────────────────────
class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days});
  final List<HeatmapDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox();

    final Map<String, HeatmapDay> dayMap = {for (final d in days) d.date: d};
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final startOffset = (yearStart.weekday - 1) % 7;
    final start = yearStart.subtract(Duration(days: startOffset));
    const totalWeeks = 53;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month labels
                Row(
                  children: _buildMonthLabels(start, totalWeeks),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(totalWeeks, (week) {
                    return Column(
                      children: List.generate(7, (day) {
                        final date =
                            start.add(Duration(days: week * 7 + day));
                        if (date.isAfter(now)) {
                          return const SizedBox(width: 12, height: 12);
                        }
                        final dateStr =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final hd = dayMap[dateStr];
                        return Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: _cellColor(hd),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Less',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.darkTextSecondary)),
              const SizedBox(width: 4),
              ...[0, 1, 2, 3, 4].map((v) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: _legendColor(v),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
              const SizedBox(width: 4),
              const Text('More',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.darkTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthLabels(DateTime start, int totalWeeks) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final labels = <Widget>[];
    int lastMonth = -1;
    for (int w = 0; w < totalWeeks; w++) {
      final date = start.add(Duration(days: w * 7));
      if (date.month != lastMonth) {
        labels.add(SizedBox(
          width: 48,
          child: Text(months[date.month],
              style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.darkTextSecondary)),
        ));
        lastMonth = date.month;
      }
    }
    return labels;
  }

  Color _cellColor(HeatmapDay? hd) {
    if (hd == null) return AppColors.darkBorder.withOpacity(0.4);
    if (hd.isProductive) return AppColors.success;
    if (hd.value == 1) return AppColors.success.withOpacity(0.4);
    return AppColors.darkBorder.withOpacity(0.5);
  }

  Color _legendColor(int v) {
    switch (v) {
      case 0: return AppColors.darkBorder.withOpacity(0.4);
      case 1: return AppColors.success.withOpacity(0.2);
      case 2: return AppColors.success.withOpacity(0.4);
      case 3: return AppColors.success.withOpacity(0.7);
      default: return AppColors.success;
    }
  }
}

// ── Insight tile ──────────────────────────────────────────────────────────────
class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});
  final AnalyticsInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = insight.type == 'strength'
        ? AppColors.success
        : insight.type == 'weakness'
            ? AppColors.danger
            : AppColors.welfareBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Center(
              child: Text(_icon(insight),
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 2),
                Text(insight.description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _icon(AnalyticsInsight i) {
    if (i.icon != null && i.icon!.isNotEmpty) return i.icon!;
    switch (i.type) {
      case 'strength': return '💪';
      case 'weakness': return '⚠️';
      default: return '💡';
    }
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary)),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.flameOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : AppColors.darkTextSecondary)),
      ),
    );
  }
}
