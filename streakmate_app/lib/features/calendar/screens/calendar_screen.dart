import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/calendar_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final user = ref.watch(authProvider).user;

    // Account creation date — dates before this are greyed + unclickable
    final accountCreatedDate = user?.createdAt != null
        ? DateTime(
            user!.createdAt!.year,
            user.createdAt!.month,
            user.createdAt!.day,
          )
        : null;

    ref.listen<CalendarState>(calendarProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.danger),
        );
        ref.read(calendarProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.darkTextPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    const Text('Calendar',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.flameOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.flameOrange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            '${user?.currentStreakDays ?? 0} days',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.flameOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Month navigator ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => ref
                          .read(calendarProvider.notifier)
                          .goToPreviousMonth(),
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.darkTextPrimary, size: 28),
                    ),
                    Text(
                      _formatMonth(state.currentMonth),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary),
                    ),
                    IconButton(
                      onPressed: _canGoNext(state.currentMonth)
                          ? () => ref
                              .read(calendarProvider.notifier)
                              .goToNextMonth()
                          : null,
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _canGoNext(state.currentMonth)
                            ? AppColors.darkTextPrimary
                            : AppColors.darkBorder,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Day of week headers ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkTextSecondary)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

            // ── Calendar grid ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: state.loadingMonth
                    ? const SizedBox(
                        height: 280,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.flameOrange),
                        ),
                      )
                    : _CalendarGrid(
                        month: state.month,
                        currentMonth: state.currentMonth,
                        accountCreatedDate: accountCreatedDate,
                        onDayTap: (date) async {
                          await ref
                              .read(calendarProvider.notifier)
                              .loadDay(date);
                          if (context.mounted) {
                            _showDaySheet(context, ref, date);
                          }
                        },
                      ),
              ),
            ),

            // ── Legend ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: const [
                    _LegendItem(color: AppColors.success, label: 'Completed'),
                    _LegendItem(color: AppColors.warning, label: 'Partial'),
                    _LegendItem(color: AppColors.danger, label: 'Missed'),
                    _LegendItem(color: AppColors.welfareBlue, label: 'Freeze'),
                    _LegendItem(color: AppColors.prayerPurple, label: 'Cheat Day'),
                  ],
                ),
              ),
            ),

            // ── Monthly summary ───────────────────────────────────
            if (state.month != null)
              SliverToBoxAdapter(
                child: _MonthlySummary(month: state.month!),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    if (parts.length < 2) return month;
    final year = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${names[m]} $year';
  }

  bool _canGoNext(String currentMonth) {
    final now = DateTime.now();
    final thisMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return currentMonth.compareTo(thisMonth) < 0;
  }

  void _showDaySheet(BuildContext context, WidgetRef ref, String date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DayDetailSheet(date: date, ref: ref),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.currentMonth,
    required this.accountCreatedDate,
    required this.onDayTap,
  });

  final CalendarMonth? month;
  final String currentMonth;
  final DateTime? accountCreatedDate;
  final ValueChanged<String> onDayTap;

  @override
  Widget build(BuildContext context) {
    final parts = currentMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;

    final firstDay = DateTime(year, m, 1);
    // Monday-based offset: Mon=0 … Sun=6
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNumber = cellIndex - startOffset + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 48));
            }

            final cellDate = DateTime(year, m, dayNumber);
            final dateStr =
                '$year-${m.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';

            // ── Before account creation → greyed, unclickable ──
            final bool isBeforeAccount = accountCreatedDate != null &&
                cellDate.isBefore(accountCreatedDate!);

            // ── Future dates → unclickable ─────────────────────
            final bool isFuture = cellDate.isAfter(todayOnly);

            if (isBeforeAccount) {
              return Expanded(
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              );
            }

            // ── Determine status from API data ─────────────────
            final dayData = month?.days[dateStr];
            DayStatus status;

            if (isFuture) {
              status = DayStatus.future;
            } else if (dayData != null) {
              status = dayData.status;
            } else if (cellDate == todayOnly) {
              status = DayStatus.today;
            } else {
              status = DayStatus.missed;
            }
          debugPrint('[CalGrid] $dateStr → status=$status bg=${_bgColor(status)}');
            return Expanded(
              child: GestureDetector(
                onTap: isFuture ? null : () => onDayTap(dateStr),
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _bgColor(status),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _borderColor(status),
                      width: status == DayStatus.today ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: status == DayStatus.today ||
                                  status == DayStatus.completed
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: _textColor(status),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        child: _StatusDot(status: status),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Color _bgColor(DayStatus s) {
    switch (s) {
      case DayStatus.completed:
        return AppColors.success.withOpacity(0.18);
      case DayStatus.partial:
        return AppColors.warning.withOpacity(0.14);
      case DayStatus.missed:
        return AppColors.danger.withOpacity(0.12);
      case DayStatus.freeze:
        return AppColors.welfareBlue.withOpacity(0.15);
      case DayStatus.cheat:
        return AppColors.prayerPurple.withOpacity(0.15);
      case DayStatus.today:
        return AppColors.flameOrange.withOpacity(0.18);
      case DayStatus.future:
        return Colors.transparent;
      default:
        return AppColors.darkSurface;
    }
  }

  Color _borderColor(DayStatus s) {
    switch (s) {
      case DayStatus.completed:
        return AppColors.success.withOpacity(0.5);
      case DayStatus.partial:
        return AppColors.warning.withOpacity(0.4);
      case DayStatus.missed:
        return AppColors.danger.withOpacity(0.4);
      case DayStatus.freeze:
        return AppColors.welfareBlue.withOpacity(0.4);
      case DayStatus.cheat:
        return AppColors.prayerPurple.withOpacity(0.4);
      case DayStatus.today:
        return AppColors.flameOrange;
      case DayStatus.future:
        return AppColors.darkBorder.withOpacity(0.3);
      default:
        return AppColors.darkBorder;
    }
  }

  Color _textColor(DayStatus s) {
    switch (s) {
      case DayStatus.completed:
        return AppColors.success;
      case DayStatus.missed:
        return AppColors.danger;
      case DayStatus.today:
        return AppColors.flameOrange;
      case DayStatus.freeze:
        return AppColors.welfareBlue;
      case DayStatus.cheat:
        return AppColors.prayerPurple;
      case DayStatus.partial:
        return AppColors.warning;
      case DayStatus.future:
        return AppColors.darkTextSecondary.withOpacity(0.4);
      default:
        return AppColors.darkTextSecondary;
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DayStatus.completed:
        return const Icon(Icons.check_rounded,
            size: 10, color: AppColors.success);
      case DayStatus.missed:
        return const Icon(Icons.close_rounded,
            size: 10, color: AppColors.danger);
      case DayStatus.freeze:
        return const Text('❄️', style: TextStyle(fontSize: 9));
      case DayStatus.cheat:
        return const Text('🎭', style: TextStyle(fontSize: 9));
      case DayStatus.partial:
        return Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
              color: AppColors.warning, shape: BoxShape.circle),
        );
      case DayStatus.today:
        return Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
              color: AppColors.flameOrange, shape: BoxShape.circle),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Monthly summary ────────────────────────────────────────────────────────────
class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.month});
  final CalendarMonth month;

  @override
  Widget build(BuildContext context) {
    int completed = 0, partial = 0, missed = 0, freeze = 0;
    for (final day in month.days.values) {
      switch (day.status) {
        case DayStatus.completed: completed++; break;
        case DayStatus.partial:   partial++;   break;
        case DayStatus.missed:    missed++;    break;
        case DayStatus.freeze:
        case DayStatus.cheat:     freeze++;    break;
        default: break;
      }
    }
    final total = completed + partial + missed + freeze;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Month',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryTile(emoji: '✅', value: '$completed', label: 'Productive', color: AppColors.success),
              _SummaryTile(emoji: '🟡', value: '$partial',   label: 'Partial',    color: AppColors.warning),
              _SummaryTile(emoji: '❌', value: '$missed',    label: 'Missed',     color: AppColors.danger),
              _SummaryTile(emoji: '❄️', value: '$freeze',    label: 'Protected',  color: AppColors.welfareBlue),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (completed > 0) Expanded(flex: completed, child: Container(color: AppColors.success)),
                    if (partial > 0)   Expanded(flex: partial,   child: Container(color: AppColors.warning)),
                    if (freeze > 0)    Expanded(flex: freeze,    child: Container(color: AppColors.welfareBlue)),
                    if (missed > 0)    Expanded(flex: missed,    child: Container(color: AppColors.danger)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              total > 0
                  ? '${((completed / total) * 100).round()}% productive days this month'
                  : 'No data yet',
              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.emoji, required this.value, required this.label, required this.color});
  final String emoji, value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}

// ── Day detail bottom sheet ────────────────────────────────────────────────────
class _DayDetailSheet extends ConsumerWidget {
  const _DayDetailSheet({required this.date, required this.ref});
  final String date;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final detail = state.selectedDay;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text(_formatDate(date),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary)),
                const Spacer(),
                if (detail != null)
                  _StatusBadge(
                      productive: detail.isProductiveDay,
                      score: detail.productivityScore),
              ],
            ),
          ),
          Expanded(
            child: state.loadingDay
                ? const Center(child: CircularProgressIndicator(color: AppColors.flameOrange))
                : detail == null
                    ? const Center(
                        child: Text('No data for this day',
                            style: TextStyle(color: AppColors.darkTextSecondary)))
                    : detail.habits.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('😴', style: TextStyle(fontSize: 36)),
                                SizedBox(height: 10),
                                Text('No habits logged',
                                    style: TextStyle(color: AppColors.darkTextSecondary)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: detail.habits.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final h = detail.habits[i];
                              final color = h.habitColor != null
                                  ? Color(int.parse(h.habitColor!.replaceFirst('#', '0xFF')))
                                  : AppColors.flameOrange;
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: h.isCompleted
                                        ? color.withOpacity(0.4)
                                        : AppColors.darkBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(h.habitIcon ?? '⭐',
                                        style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(h.habitName ?? 'Habit',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.darkTextPrimary)),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: h.completionPercentage / 100,
                                              minHeight: 4,
                                              backgroundColor: AppColors.darkBorder,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  h.isCompleted ? AppColors.success : color),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('${h.completionPercentage}% complete',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.darkTextSecondary)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      h.isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: h.isCompleted
                                          ? AppColors.success
                                          : AppColors.darkTextSecondary,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) { return date; }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.productive, required this.score});
  final bool productive;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: productive
            ? AppColors.success.withOpacity(0.15)
            : AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: productive
              ? AppColors.success.withOpacity(0.4)
              : AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Text(
        productive ? '✅ Productive' : '❌ Missed',
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: productive ? AppColors.success : AppColors.danger),
      ),
    );
  }
}
