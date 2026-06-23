import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../models/remote/habit_template_model.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/goal_card.dart';
import '../widgets/step_indicator.dart';

/// goal_selection_screen.dart
/// Onboarding step 2/4 — single-select. Maps to POST /onboarding/goal
/// body: { selectedGoal }.
class GoalSelectionScreen extends ConsumerWidget {
  const GoalSelectionScreen({super.key});

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
      debugPrint('[Onboarding] submitGoal called — selected: ${state.selectedGoal}');
      final success = await ref.read(onboardingProvider.notifier).submitGoal();
      debugPrint('[Onboarding] submitGoal result — success: $success');
      debugPrint('[Onboarding] current error: ${ref.read(onboardingProvider).errorMessage}');
      if (success && context.mounted) {
        debugPrint('[Onboarding] navigating to habits screen');
        context.go(RouteNames.onboardingHabits);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg2.png', // Make sure to save screen 2's background as bg2.png here
              fit: BoxFit.cover,
            ),
          ),
          
          // Foreground UI Elements
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const StepIndicator(current: 2, total: 4),
                      const Spacer(),
                      IconButton(
                        onPressed: isSubmitting ? null : () => context.go(RouteNames.onboardingWelcome),
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
                            TextSpan(text: "What's your "),
                            TextSpan(text: 'purpose?', style: TextStyle(color: AppColors.sproutGreen)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Choose what matters most to you.', style: AppTextStyles.lightSubtitle),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: kGoalOptions.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, index) {
                        final goal = kGoalOptions[index];
                        return GoalCard(
                          icon: goal.icon(),
                          title: goal.title,
                          subtitle: goal.subtitle,
                          color: Color(int.parse(goal.colorHex.replaceFirst('#', '0xFF'))),
                          selected: state.selectedGoal == goal.value,
                          onTap: () => ref.read(onboardingProvider.notifier).selectGoal(goal.value),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: AppButton(
                    label: 'Continue',
                    isLoading: isSubmitting,
                    onPressed: state.selectedGoal == null ? null : handleContinue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}