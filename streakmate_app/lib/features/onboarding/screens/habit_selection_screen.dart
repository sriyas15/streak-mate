import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../models/remote/habit_template_model.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/habit_selection_card.dart';
import '../widgets/step_indicator.dart';

/// habit_selection_screen.dart
/// Onboarding step 3/4 — multi-select habit picker with 3D island cards.
/// Island asset mapping (matches mockup order):
///   island1 → gym      (Workout)
///   island2 → prayer   (Prayer / Quran)
///   island3 → study    (Study)
///   island4 → diet     (Nutrition)
///   island5 → welfare  (Water Intake / Welfare)
const Map<String, String> _kIslandAssets = {
  'gym':     'assets/images/island1.png',
  'prayer':  'assets/images/island2.png',
  'study':   'assets/images/island3.png',
  'diet':    'assets/images/island4.png',
  'welfare': 'assets/images/island5.png',
};

class HabitSelectionScreen extends ConsumerWidget {
  const HabitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isSubmitting = state.status == OnboardingSubmitStatus.submitting;

    // Only the 5 mapped templates, in the exact order defined in _kIslandAssets
    final orderedCategories = _kIslandAssets.keys.toList();
    final pickableTemplates = orderedCategories
        .map((cat) => kHabitTemplates.firstWhere((t) => t.category == cat))
        .toList();

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.status == OnboardingSubmitStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.danger),
        );
        ref.read(onboardingProvider.notifier).clearError();
      }
    });

    Future<void> handleContinue() async {
      final success = await ref.read(onboardingProvider.notifier).submitHabits();
      if (success && context.mounted) {
        context.go(RouteNames.onboardingSubtasks);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg3.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header row ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const StepIndicator(current: 3, total: 4),
                      const Spacer(),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(RouteNames.onboardingGoal),
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.lightTextPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Title ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: AppTextStyles.lightHeadline,
                          children: [
                            TextSpan(text: 'Pick your\n'),
                            TextSpan(
                              text: 'habits',
                              style: TextStyle(color: AppColors.welfareBlue),
                            ),
                            TextSpan(text: ' ✨'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You can always adjust later.',
                        style: AppTextStyles.lightSubtitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Scrollable grid ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pickableTemplates.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final template = pickableTemplates[index];
                            final color = Color(int.parse(
                                template.colorHex.replaceFirst('#', '0xFF')));
                            return HabitSelectionCard(
                              islandAsset: _kIslandAssets[template.category]!,
                              label: template.name,
                              color: color,
                              selected: state.selectedCategories
                                  .contains(template.category),
                              onTap: () => ref
                                  .read(onboardingProvider.notifier)
                                  .toggleCategory(template.category),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Add Custom Habit row ─────────────────────────────
                        _AddCustomHabitRow(
                          selected:
                              state.selectedCategories.contains('custom'),
                          onTap: () => ref
                              .read(onboardingProvider.notifier)
                              .toggleCategory('custom'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── Continue button ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: AppButton(
                    label: 'Continue',
                    isLoading: isSubmitting,
                    backgroundColor: AppColors.welfareBlue,
                    onPressed:
                        state.selectedCategories.isEmpty ? null : handleContinue,
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

class _AddCustomHabitRow extends StatelessWidget {
  const _AddCustomHabitRow({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.welfareBlue : AppColors.lightCardBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.add_circle_outline,
              color: selected
                  ? AppColors.welfareBlue
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Custom Habit',
                      style: AppTextStyles.lightCardTitle),
                  Text('Make it your own',
                      style: AppTextStyles.lightCardSubtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }
}