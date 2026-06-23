import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../models/remote/subtask_model.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/subtask_tile.dart';

/// subtask_setup_screen.dart
/// Onboarding step 4/4 — combined view of ALL selected habits' subtasks
/// (per your call: one screen, not a per-habit stepper). Each habit gets
/// its own section header + colored subtask list, matching the
/// "Setup Workout" card style but stacked for every selected habit.
///
/// Maps to POST /onboarding/subtasks
/// body: { habitSubtasks: [{ habitId, enabledSubtaskIds, customSubtasks? }] }
class SubtaskSetupScreen extends ConsumerWidget {
  const SubtaskSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isSubmitting = state.status == OnboardingSubmitStatus.submitting;

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.status == OnboardingSubmitStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.danger),
        );
        ref.read(onboardingProvider.notifier).clearError();
      }
    });

    Future<void> handleContinue() async {
      final success = await ref.read(onboardingProvider.notifier).submitSubtasks();
      if (success && context.mounted) {
        context.go(RouteNames.onboardingReminders);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const StepIndicator(current: 4, total: 4),
                  const Spacer(),
                  IconButton(
                    onPressed: isSubmitting ? null : () => context.go(RouteNames.onboardingHabits),
                    icon: const Icon(Icons.arrow_back, color: AppColors.lightTextPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: AppTextStyles.lightHeadline,
                      children: [
                        TextSpan(text: 'Set up your '),
                        TextSpan(text: 'tasks', style: TextStyle(color: AppColors.prayerPurple)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the sub-tasks you want to include.',
                    style: AppTextStyles.lightSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.habits.length,
                itemBuilder: (context, habitIndex) {
                  final habit = state.habits[habitIndex];
                  final color = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
                  final enabled = state.enabledSubtaskIds[habit.id] ?? {};

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(habit.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              habit.name,
                              style: AppTextStyles.lightCardTitle.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...habit.subtasks.map((subtask) {
                          final meta = _metaLabel(subtask);
                          return SubtaskTile(
                            icon: _iconForInputType(subtask.inputType),
                            name: subtask.name,
                            metaLabel: meta,
                            enabled: enabled.contains(subtask.id),
                            color: color,
                            isOptionalLabel: !subtask.isRequired,
                            onToggle: () => ref
                                .read(onboardingProvider.notifier)
                                .toggleSubtask(habit.id, subtask.id),
                          );
                        }),
                        _AddCustomSubtaskRow(
                          color: color,
                          onAdd: (name) => ref
                              .read(onboardingProvider.notifier)
                              .addCustomSubtaskDraft(habit.id, name),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: AppButton(
                label: 'Continue',
                isLoading: isSubmitting,
                backgroundColor: AppColors.prayerPurple,
                onPressed: handleContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metaLabel(SubtaskModel subtask) {
    if (subtask.inputType == 'timer' && subtask.targetValue != null) {
      return '${subtask.targetValue} ${subtask.unit ?? "min"}';
    }
    if (subtask.inputType == 'quantity' && subtask.targetValue != null) {
      return '${subtask.targetValue} ${subtask.unit ?? ""}';
    }
    if (!subtask.isRequired) return 'Optional';
    return 'Required';
  }

  String _iconForInputType(String inputType) {
    switch (inputType) {
      case 'timer':
        return '⏱️';
      case 'quantity':
        return '📊';
      case 'count':
        return '🔢';
      default:
        return '✅';
    }
  }
}

class _AddCustomSubtaskRow extends StatefulWidget {
  const _AddCustomSubtaskRow({required this.color, required this.onAdd});
  final Color color;
  final ValueChanged<String> onAdd;

  @override
  State<_AddCustomSubtaskRow> createState() => _AddCustomSubtaskRowState();
}

class _AddCustomSubtaskRowState extends State<_AddCustomSubtaskRow> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightCardBorder, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: widget.color),
              const SizedBox(width: 6),
              Text(
                'Add custom sub-task',
                style: AppTextStyles.lightCardSubtitle.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Read 20 pages',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.check, color: widget.color),
          ),
        ],
      ),
    );
  }
}
