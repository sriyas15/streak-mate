import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/remote/habit_model.dart';

final _remindersProvider = FutureProvider<List<HabitModel>>((ref) async {
  final r = await DioClient.instance.dio.get('/habits');
  if (r.statusCode == 200) {
    return (r.data['data']['habits'] as List)
        .map((h) => HabitModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }
  return [];
});

class HabitRemindersScreen extends ConsumerStatefulWidget {
  const HabitRemindersScreen({super.key});

  @override
  ConsumerState<HabitRemindersScreen> createState() =>
      _HabitRemindersScreenState();
}

class _HabitRemindersScreenState
    extends ConsumerState<HabitRemindersScreen> {
  // habitId → local toggle state
  final Map<String, bool> _enabled = {};
  // habitId → time string "HH:MM"
  final Map<String, String> _times = {};
  final Set<String> _saving = {};

  void _init(List<HabitModel> habits) {
    for (final h in habits) {
      if (!_enabled.containsKey(h.id)) {
        _enabled[h.id] = h.reminderEnabled;
        _times[h.id] =
            h.reminderTimes.isNotEmpty ? h.reminderTimes.first : '08:00';
      }
    }
  }

  Future<void> _toggle(HabitModel habit, bool value) async {
    setState(() {
      _enabled[habit.id] = value;
      _saving.add(habit.id);
    });
    try {
      await DioClient.instance.dio.patch(
        '/habits/${habit.id}',
        data: {
          'reminderEnabled': value,
          'reminderTimes': value ? [_times[habit.id]] : [],
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (_) {
      setState(() => _enabled[habit.id] = !value); // rollback
    } finally {
      setState(() => _saving.remove(habit.id));
    }
  }

  Future<void> _pickTime(BuildContext ctx, HabitModel habit) async {
    final current = _times[habit.id] ?? '08:00';
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: ctx,
      initialTime: initial,
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.flameOrange),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _times[habit.id] = formatted;
      _saving.add(habit.id);
    });
    try {
      await DioClient.instance.dio.patch(
        '/habits/${habit.id}',
        data: {'reminderTimes': [formatted]},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } finally {
      setState(() => _saving.remove(habit.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(_remindersProvider);

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
        title: const Text('Habit Reminders',
            style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: habitsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.flameOrange)),
        error: (e, _) => Center(
          child: Text('$e',
              style: const TextStyle(color: AppColors.darkTextSecondary)),
        ),
        data: (habits) {
          _init(habits);
          if (habits.isEmpty) {
            return const Center(
              child: Text('No habits yet. Create one first!',
                  style:
                      TextStyle(color: AppColors.darkTextSecondary)),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.flameOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.flameOrange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toggle reminders per habit and tap the time to change it.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              ...habits.map((habit) {
                final color = Color(
                    int.parse(habit.color.replaceFirst('#', '0xFF')));
                final enabled = _enabled[habit.id] ?? false;
                final time = _times[habit.id] ?? '08:00';
                final saving = _saving.contains(habit.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: enabled
                          ? color.withOpacity(0.4)
                          : AppColors.darkBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(habit.icon,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkTextPrimary)),
                            GestureDetector(
                              onTap: enabled
                                  ? () => _pickTime(context, habit)
                                  : null,
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 12,
                                      color: enabled
                                          ? color
                                          : AppColors.darkTextSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    enabled ? 'Remind at $time' : 'Off',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: enabled
                                            ? color
                                            : AppColors.darkTextSecondary,
                                        fontWeight: enabled
                                            ? FontWeight.w600
                                            : FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Toggle
                      saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.flameOrange))
                          : Switch(
                              value: enabled,
                              activeColor: color,
                              onChanged: (v) => _toggle(habit, v),
                            ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}