import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/remote/habit_template_model.dart';
import '../../../providers/add_habit_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../shared/widgets/add_custom_subtask_row.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  int _step = 1; // 1 = template picker, 2 = customise
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _selectTemplate(HabitTemplate t) {
    ref.read(addHabitProvider.notifier).selectTemplate(
          category: t.category,
          name: t.name,
          icon: t.icon,
          color: t.colorHex,
        );
    _nameCtrl.text = t.name;
    setState(() => _step = 2);
  }

  Future<void> _save() async {
    ref.read(addHabitProvider.notifier).setName(_nameCtrl.text);
    ref.read(addHabitProvider.notifier).setDescription(_descCtrl.text);

    final success = await ref.read(addHabitProvider.notifier).save();
    if (success && mounted) {
      ref.read(homeProvider.notifier).loadToday();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addHabitProvider);

    ref.listen<AddHabitState>(addHabitProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.danger),
        );
        ref.read(addHabitProvider.notifier).clearError();
      }
    });

    return PopScope(
      canPop: _step == 1, // ✅ only allow system back to pop when on step 1
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 2) {
          setState(() => _step = 1); // ✅ system back on step 2 → go to step 1
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _step == 1
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkTextPrimary,
            size: 20,
          ),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 1 ? 'Choose a Habit' : 'Set Up Habit',
          style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _step / 2,
            backgroundColor: AppColors.darkBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.flameOrange),
            minHeight: 3,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _step == 1
            ? _TemplatePicker(
                key: const ValueKey('step1'),
                onSelect: _selectTemplate,
              )
            : _CustomiseForm(
                key: const ValueKey('step2'),
                state: state,
                nameCtrl: _nameCtrl,
                descCtrl: _descCtrl,
                onSave: _save,
              ),
      ),
    )
    );
  }
}

// ── Step 1: Template picker ──────────────────────────────────────────────────
class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({super.key, required this.onSelect});
  final ValueChanged<HabitTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose a habit to build',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Pick a template to get started quickly.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkTextSecondary
                          .withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final t = kHabitTemplates[i];
                final color = Color(
                    int.parse(t.colorHex.replaceFirst('#', '0xFF')));
                return _TemplateCard(
                  template: t,
                  color: color,
                  onTap: () => onSelect(t),
                );
              },
              childCount: kHabitTemplates.length,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.color,
    required this.onTap,
  });
  final HabitTemplate template;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(template.icon,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              template.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${template.subtasks.length} subtasks',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Customise form ───────────────────────────────────────────────────
class _CustomiseForm extends ConsumerWidget {
  const _CustomiseForm({
    super.key,
    required this.state,
    required this.nameCtrl,
    required this.descCtrl,
    required this.onSave,
  });

  final AddHabitState state;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onSave;

  static const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = state.selectedColor != null
        ? Color(int.parse(
            state.selectedColor!.replaceFirst('#', '0xFF')))
        : AppColors.flameOrange;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(state.selectedIcon ?? '⭐',
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.selectedName ?? '',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary),
                  ),
                  Text(state.selectedCategory ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _Label(label: 'HABIT NAME'),
        _DarkField(
          controller: nameCtrl,
          hint: 'e.g. Morning Workout',
          icon: Icons.edit_rounded,
          color: color,
          onChanged: (v) =>
              ref.read(addHabitProvider.notifier).setName(v),
        ),
        const SizedBox(height: 16),

        _Label(label: 'DESCRIPTION (OPTIONAL)'),
        _DarkField(
          controller: descCtrl,
          hint: 'What is this habit about?',
          icon: Icons.notes_rounded,
          color: color,
          maxLines: 3,
          onChanged: (v) =>
              ref.read(addHabitProvider.notifier).setDescription(v),
        ),
        const SizedBox(height: 20),

        _Label(label: 'SCHEDULE'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FreqChip(
                    label: 'Daily',
                    selected: state.frequency == 'daily',
                    color: color,
                    onTap: () => ref
                        .read(addHabitProvider.notifier)
                        .setFrequency('daily'),
                  ),
                  const SizedBox(width: 10),
                  _FreqChip(
                    label: 'Custom days',
                    selected: state.frequency == 'custom',
                    color: color,
                    onTap: () => ref
                        .read(addHabitProvider.notifier)
                        .setFrequency('custom'),
                  ),
                ],
              ),
              if (state.frequency == 'custom') ...[
                const SizedBox(height: 14),
                const Text('Active days',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final active = state.activeDays.contains(i);
                    return GestureDetector(
                      onTap: () => ref
                          .read(addHabitProvider.notifier)
                          .toggleDay(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? color.withOpacity(0.2)
                              : AppColors.darkSurfaceElevated,
                          border: Border.all(
                            color: active
                                ? color
                                : AppColors.darkBorder,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _days[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? color
                                  : AppColors.darkTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_subtasksForCategory(state.selectedCategory).isNotEmpty) ...[
          _Label(label: 'DEFAULT SUBTASKS'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                ..._subtasksForCategory(state.selectedCategory)
                    .map((s) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                _iconForType(s.inputType),
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(s.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors
                                            .darkTextPrimary)),
                              ),
                              if (s.targetValue != null &&
                                  s.unit != null)
                                Text(
                                    '${s.targetValue} ${s.unit}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors
                                            .darkTextSecondary)),
                              if (!s.isRequired)
                                Container(
                                  margin:
                                      const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkBorder,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: const Text('Optional',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors
                                              .darkTextSecondary)),
                                ),
                            ],
                          ),
                        )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 12,
                        color: AppColors.darkTextSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'These subtasks are added automatically. You can edit them from the habit detail screen.',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Custom subtasks ─────────────────────────────────────
        _Label(label: 'CUSTOM SUBTASKS'),
        ...state.customSubtasks.asMap().entries.map((entry) {
          final i = entry.key;
          final name = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.check_box_outline_blank_rounded,
                    size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkTextPrimary)),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(addHabitProvider.notifier)
                      .removeCustomSubtask(i),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          );
        }),
        AddCustomSubtaskRow(
          color: color,
          onAdd: (name) =>
              ref.read(addHabitProvider.notifier).addCustomSubtask(name),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: state.saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: color.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: state.saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Save Habit',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  List<SubtaskTemplate> _subtasksForCategory(String? category) {
    if (category == null) return [];
    final template = kHabitTemplates
        .where((t) => t.category == category)
        .firstOrNull;
    return template?.subtasks ?? [];
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'timer':
        return Icons.timer_outlined;
      case 'quantity':
        return Icons.bar_chart_rounded;
      default:
        return Icons.check_box_outline_blank_rounded;
    }
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
              letterSpacing: 0.5)),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.color,
    this.maxLines = 1,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color color;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(
            color: AppColors.darkTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.darkTextSecondary, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}

class _FreqChip extends StatelessWidget {
  const _FreqChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.darkSurfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.darkBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}