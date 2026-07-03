import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/analytics_model.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[InsightsScreen] initState called');
    Future.microtask(() {
      debugPrint('[InsightsScreen] calling loadAll');
      ref.read(analyticsProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
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
          // Period toggle — week / month
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
              child: CircularProgressIndicator(color: AppColors.flameOrange))
          : RefreshIndicator(
              color: AppColors.flameOrange,
              backgroundColor: AppColors.darkSurface,
              onRefresh: () =>
                  ref.read(analyticsProvider.notifier).loadAll(),
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // ── Motivational heading ──────────────────────
                  _MotivationalHeader(state: state),
                  const SizedBox(height: 20),

                  // ── Line chart ────────────────────────────────
                  if (state.overview?.dailyActivity.isNotEmpty == true) ...[
                    _ActivityChart(
                      data: state.overview!.dailyActivity,
                      period: state.period,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Stat cards row ────────────────────────────
                  _StatCardsRow(
                    overview: state.overview,
                    user: user,
                  ),
                  const SizedBox(height: 20),

                  // ── Category performance ──────────────────────
                  if (state.categories.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Category Performance',
                      subtitle: state.period == AnalyticsPeriod.week
                          ? 'This week'
                          : 'This month',
                    ),
                    const SizedBox(height: 12),
                    ...state.categories.map(
                        (c) => _CategoryRow(category: c)),
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

                  // ── Focus areas / Insights ────────────────────
                  if (state.insights.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Focus Areas',
                      subtitle: 'See where you can improve',
                    ),
                    const SizedBox(height: 12),
                    ...state.insights.map(
                        (i) => _InsightTile(insight: i)),
                  ],
                ],
              ),
            ),
    );
  }
}

// ── Motivational header ───────────────────────────────────────────────────────
class _MotivationalHeader extends StatelessWidget {
  const _MotivationalHeader({required this.state});
  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final rate = state.overview?.consistencyRate ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.flameOrange.withOpacity(0.2),
            AppColors.xpGold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.flameOrange.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.motivationalHeading,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary)),
                const SizedBox(height: 4),
                Text(state.motivationalSubtitle,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary)),
                const SizedBox(height: 12),
                // Consistency bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (rate / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        AppColors.flameOrange.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.flameOrange),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${rate.round()}% consistency',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.flameOrange,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            rate >= 90
                ? '🔥'
                : rate >= 70
                    ? '💪'
                    : rate >= 50
                        ? '🌱'
                        : '💡',
            style: const TextStyle(fontSize: 48),
          ),
        ],
      ),
    );
  }
}

// ── Line chart ────────────────────────────────────────────────────────────────
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.data, required this.period});
  final List<DailyActivity> data;
  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    // Build spots — y = completionRate (0-100)
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.completionRate);
    }).toList();

    final maxY = 100.0;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
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
                  '${v.toInt()}%',
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
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[i].dayLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.darkTextSecondary),
                    ),
                  );
                },
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
                  radius: 4,
                  color: spot.y >= 100
                      ? AppColors.success
                      : AppColors.flameOrange,
                  strokeWidth: 2,
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
              getTooltipColor: (_) => AppColors.darkSurfaceElevated,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.round()}%',
                        const TextStyle(
                            color: AppColors.flameOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat cards row ────────────────────────────────────────────────────────────
class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({required this.overview, required this.user});
  final AnalyticsOverview? overview;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          emoji: '📊',
          value: '${overview?.consistencyRate.round() ?? 0}%',
          label: 'Consistency',
          color: AppColors.prayerPurple,
        ),
        const SizedBox(width: 10),
        _StatCard(
          emoji: '🔥',
          value: '${user?.currentStreakDays ?? 0}',
          label: 'Best Streak',
          color: AppColors.flameOrange,
        ),
        const SizedBox(width: 10),
        _StatCard(
          emoji: '✅',
          value: '${overview?.totalHabitsCompleted ?? 0}',
          label: 'Completed',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkTextSecondary,
                    height: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── Category performance row ──────────────────────────────────────────────────
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(color),
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

// ── Heatmap grid ──────────────────────────────────────────────────────────────
class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days});
  final List<HeatmapDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox();

    // Group by week (columns of 7)
    final Map<String, HeatmapDay> dayMap = {
      for (final d in days) d.date: d
    };

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    // Start from Monday of the week containing Jan 1
    final startOffset = (yearStart.weekday - 1) % 7;
    final start =
        yearStart.subtract(Duration(days: startOffset));
    final totalWeeks = 53;

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
          // Month labels
          _MonthLabels(start: start, totalWeeks: totalWeeks),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(totalWeeks, (week) {
                return Column(
                  children: List.generate(7, (day) {
                    final date = start.add(
                        Duration(days: week * 7 + day));
                    if (date.year != now.year &&
                        date.isAfter(now)) {
                      return const SizedBox(width: 11, height: 11);
                    }
                    final dateStr =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final hd = dayMap[dateStr];
                    final color = _cellColor(hd);
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
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

class _MonthLabels extends StatelessWidget {
  const _MonthLabels({required this.start, required this.totalWeeks});
  final DateTime start;
  final int totalWeeks;

  @override
  Widget build(BuildContext context) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final labels = <Widget>[];
    int lastMonth = -1;

    for (int w = 0; w < totalWeeks; w++) {
      final date = start.add(Duration(days: w * 7));
      if (date.month != lastMonth) {
        labels.add(SizedBox(
          width: 12 * 4.5,
          child: Text(months[date.month],
              style: const TextStyle(
                  fontSize: 9, color: AppColors.darkTextSecondary)),
        ));
        lastMonth = date.month;
      }
    }

    return Row(children: labels);
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
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(insight.icon ?? _defaultIcon(insight.type),
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

  String _defaultIcon(String type) {
    switch (type) {
      case 'strength': return '💪';
      case 'weakness': return '⚠️';
      default: return '💡';
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────
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

// ── Period toggle chip ────────────────────────────────────────────────────────
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
          color: selected
              ? AppColors.flameOrange
              : Colors.transparent,
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