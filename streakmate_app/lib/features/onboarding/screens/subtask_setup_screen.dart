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
import '../../../shared/widgets/add_custom_subtask_row.dart';

/// subtask_setup_screen.dart
class SubtaskSetupScreen extends ConsumerWidget {
  const SubtaskSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isSubmitting = state.status == OnboardingSubmitStatus.submitting;

    // Dynamically grab the first habit to theme the header like the mockup ("Workout")
    final dynamicTitle = state.habits.isNotEmpty ? state.habits.first.name : 'tasks';
    final dynamicIcon = state.habits.isNotEmpty ? state.habits.first.icon : '✨';
    final dynamicColor = state.habits.isNotEmpty 
        ? Color(int.parse(state.habits.first.color.replaceFirst('#', '0xFF'))) 
        : const Color(0xFF7D5BC7); // Fallback Purple

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
      body: Stack(
        children: [
          // 1. Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg4.png', // Ensure this image is added to your assets folder
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
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
                const SizedBox(height: 12),
                
                // 2. Centered Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Set up your\n',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: '$dynamicTitle ',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: dynamicColor, // Uses the habit's color (purple for workout)
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: dynamicIcon,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the sub-tasks you want\nto include.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 3. Subtask List
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
                            // Only show habit header if multiple habits were selected
                            if (state.habits.length > 1) ...[
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
                            ],
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
                            AddCustomSubtaskRow(   // was _AddCustomSubtaskRow
                              color: color,
                              onAdd: (name) => ref.read(onboardingProvider.notifier).addCustomSubtaskDraft(habit.id, name),
                            ),
],
                        ),
                      );
                    },
                  ),
                ),

                // 4. Streak Protection Banner (Static UI from Mockup)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Shield Icon Background
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7D5BC7).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: Color(0xFF7D5BC7), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Streak Protection',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                            ),
                            Text(
                              'Miss a day? Use Freeze Day\nand keep your streak alive.',
                              style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.ac_unit, color: Color(0xFF90A4E2), size: 28), // Snowflake Icon
                    ],
                  ),
                ),
                
                // 5. Final Bottom Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: AppButton(
                    label: "All Set! Let's Go 🚀", // Updated Text
                    isLoading: isSubmitting,
                    backgroundColor: const Color(0xFF7D5BC7), // Deep purple from mockup
                    onPressed: handleContinue,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4), // Soft transparent background
            border: Border.all(color: widget.color.withOpacity(0.2), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: widget.color),
              const SizedBox(width: 8),
              Text(
                'Add custom sub-task',
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
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