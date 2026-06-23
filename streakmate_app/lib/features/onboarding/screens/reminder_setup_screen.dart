import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/step_indicator.dart';

/// reminder_setup_screen.dart
/// Onboarding step 5/5 (added beyond the 4 screenshots, per your request,
/// to cover POST /onboarding/reminders). Per-habit toggle + time picker,
/// then calls setReminders + complete in one "Continue" action.
class ReminderSetupScreen extends ConsumerWidget {
  const ReminderSetupScreen({super.key});

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

    Future<void> handleFinish() async {
      final success = await ref.read(onboardingProvider.notifier).submitRemindersAndComplete();
      if (success && context.mounted) {
        context.go(RouteNames.home);
      }
    }

    Future<void> pickTime(BuildContext ctx, String habitId, String currentTime) async {
      final parts = currentTime.split(':');
      final initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
      final picked = await showTimePicker(context: ctx, initialTime: initial);
      if (picked != null) {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        ref.read(onboardingProvider.notifier).setReminderTime(habitId, formatted);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const StepIndicator(current: 5, total: 5),
                  const Spacer(),
                  IconButton(
                    onPressed: isSubmitting ? null : () => context.go(RouteNames.onboardingSubtasks),
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
                        TextSpan(text: 'Stay on '),
                        TextSpan(text: 'track', style: TextStyle(color: AppColors.warning)),
                        TextSpan(text: ' 🔔'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set reminders so you never miss a habit. You can skip this.',
                    style: AppTextStyles.lightSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final habit = state.habits[index];
                  final color = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
                  final draft = state.reminders[habit.id];
                  final enabled = draft != null;
                  final time = draft?.times.isNotEmpty == true ? draft!.times.first : '08:00';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightCardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 17))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(habit.name, style: AppTextStyles.lightCardTitle),
                              GestureDetector(
                                onTap: enabled ? () => pickTime(context, habit.id, time) : null,
                                child: Text(
                                  enabled ? 'Remind at $time' : 'No reminder',
                                  style: AppTextStyles.lightCardSubtitle.copyWith(
                                    color: enabled ? color : AppColors.lightTextSecondary,
                                    fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: enabled,
                          activeColor: color,
                          onChanged: (value) => ref
                              .read(onboardingProvider.notifier)
                              .setReminderEnabled(habit.id, value),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  AppButton(
                    label: "All Set! Let's Go",
                    isLoading: isSubmitting,
                    backgroundColor: AppColors.warning,
                    onPressed: handleFinish,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: isSubmitting ? null : handleFinish,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
