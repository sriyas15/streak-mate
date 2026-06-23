/// habit_template_model.dart
/// Mirrors backend HABIT_TEMPLATES exactly (constants.js). These are static
/// client-side mirrors used to render the onboarding UI instantly; the
/// actual Habit + Subtask documents are created server-side by
/// POST /onboarding/habits, which returns the real persisted habits
/// (see OnboardingRepository.selectHabits).
class SubtaskTemplate {
  final String name;
  final String inputType; // checkbox | quantity | timer | count
  final String? unit;
  final num? targetValue;
  final bool isRequired;
  final int displayOrder;

  const SubtaskTemplate({
    required this.name,
    required this.inputType,
    this.unit,
    this.targetValue,
    required this.isRequired,
    required this.displayOrder,
  });
}

class HabitTemplate {
  final String category;
  final String name;
  final String icon;
  final String colorHex;
  final List<SubtaskTemplate> subtasks;

  const HabitTemplate({
    required this.category,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.subtasks,
  });
}

/// Static mirror of backend HABIT_TEMPLATES — used for instant onboarding
/// UI render. Display only; never sent to the server. The server creates
/// its own Habit/Subtask docs from its own copy of this data.
const List<HabitTemplate> kHabitTemplates = [
  HabitTemplate(
    category: 'gym',
    name: 'Gym / Workout',
    icon: '🏋️',
    colorHex: '#E24B4A',
    subtasks: [
      SubtaskTemplate(name: 'Warm-up', inputType: 'timer', unit: 'min', targetValue: 10, isRequired: true, displayOrder: 0),
      SubtaskTemplate(name: 'Main workout session', inputType: 'timer', unit: 'min', targetValue: 45, isRequired: true, displayOrder: 1),
      SubtaskTemplate(name: 'Cool-down / stretch', inputType: 'timer', unit: 'min', targetValue: 10, isRequired: true, displayOrder: 2),
      SubtaskTemplate(name: 'Post-workout protein', inputType: 'quantity', unit: 'g', targetValue: 40, isRequired: false, displayOrder: 3),
    ],
  ),
  HabitTemplate(
    category: 'prayer',
    name: 'Prayer / Quran',
    icon: '🕌',
    colorHex: '#7F77DD',
    subtasks: [
      SubtaskTemplate(name: 'Fajr', inputType: 'checkbox', isRequired: true, displayOrder: 0),
      SubtaskTemplate(name: 'Dhuhr', inputType: 'checkbox', isRequired: true, displayOrder: 1),
      SubtaskTemplate(name: 'Asr', inputType: 'checkbox', isRequired: true, displayOrder: 2),
      SubtaskTemplate(name: 'Maghrib', inputType: 'checkbox', isRequired: true, displayOrder: 3),
      SubtaskTemplate(name: 'Isha', inputType: 'checkbox', isRequired: true, displayOrder: 4),
      SubtaskTemplate(name: 'Quran reading (min. 1 page)', inputType: 'count', unit: 'pages', targetValue: 1, isRequired: false, displayOrder: 5),
      SubtaskTemplate(name: 'Morning adhkar', inputType: 'checkbox', isRequired: false, displayOrder: 6),
      SubtaskTemplate(name: 'Evening adhkar', inputType: 'checkbox', isRequired: false, displayOrder: 7),
      SubtaskTemplate(name: 'Dua session', inputType: 'checkbox', isRequired: false, displayOrder: 8),
      SubtaskTemplate(name: 'Knowledge (lecture/article)', inputType: 'checkbox', isRequired: false, displayOrder: 9),
      SubtaskTemplate(name: 'Charity / Sadaqah', inputType: 'checkbox', isRequired: false, displayOrder: 10),
    ],
  ),
  HabitTemplate(
    category: 'study',
    name: 'Study',
    icon: '📚',
    colorHex: '#BA7517',
    subtasks: [
      SubtaskTemplate(name: 'Study / deep work session', inputType: 'timer', unit: 'min', targetValue: 60, isRequired: true, displayOrder: 0),
      SubtaskTemplate(name: 'Assignment / task completed', inputType: 'checkbox', isRequired: true, displayOrder: 1),
      SubtaskTemplate(name: 'Notes revised', inputType: 'checkbox', isRequired: false, displayOrder: 2),
      SubtaskTemplate(name: 'Practice problems', inputType: 'quantity', unit: 'Qs', isRequired: false, displayOrder: 3),
    ],
  ),
  HabitTemplate(
    category: 'diet',
    name: 'Diet / Nutrition',
    icon: '🥗',
    colorHex: '#1D9E75',
    subtasks: [
      SubtaskTemplate(name: 'No junk food', inputType: 'checkbox', isRequired: true, displayOrder: 0),
      SubtaskTemplate(name: 'Healthy meal eaten', inputType: 'checkbox', isRequired: true, displayOrder: 1),
      SubtaskTemplate(name: 'Calories / macros logged', inputType: 'quantity', unit: 'kcal', isRequired: false, displayOrder: 2),
      SubtaskTemplate(name: 'No late-night eating', inputType: 'checkbox', isRequired: false, displayOrder: 3),
      SubtaskTemplate(name: 'Supplements taken', inputType: 'checkbox', isRequired: false, displayOrder: 4),
    ],
  ),
  HabitTemplate(
    category: 'welfare',
    name: 'Personal Welfare',
    icon: '🌿',
    colorHex: '#185FA5',
    subtasks: [
      SubtaskTemplate(name: 'Water intake', inputType: 'quantity', unit: 'ml', targetValue: 2000, isRequired: true, displayOrder: 0),
      SubtaskTemplate(name: 'Sleep (7+ hours)', inputType: 'quantity', unit: 'hrs', targetValue: 7, isRequired: true, displayOrder: 1),
      SubtaskTemplate(name: 'Family time (phone-free)', inputType: 'checkbox', isRequired: false, displayOrder: 2),
      SubtaskTemplate(name: 'Skincare / grooming', inputType: 'checkbox', isRequired: false, displayOrder: 3),
      SubtaskTemplate(name: 'Journaling / mood log', inputType: 'checkbox', isRequired: false, displayOrder: 4),
    ],
  ),
  HabitTemplate(
    category: 'custom',
    name: 'Custom Habit',
    icon: '⭐',
    colorHex: '#888780',
    subtasks: [],
  ),
];

/// Goal options for the Purpose screen (mirrors User.selectedGoal enum).
class GoalOption {
  final String value;
  final String title;
  final String subtitle;
  final String icon;
  final String colorHex;

  const GoalOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorHex,
  });
}

const List<GoalOption> kGoalOptions = [
  GoalOption(value: 'fitness', title: 'Get Fit', subtitle: 'Stronger body, stronger you.', icon: '💪', colorHex: '#1D9E75'),
  GoalOption(value: 'spiritual', title: 'Spiritual Growth', subtitle: 'Strengthen your faith and inner peace.', icon: '🌙', colorHex: '#7F77DD'),
  GoalOption(value: 'study', title: 'Study & Learn', subtitle: 'Learn more, achieve more.', icon: '📖', colorHex: '#BA7517'),
  GoalOption(value: 'wellness', title: 'Live Healthy', subtitle: 'Better habits, better life.', icon: '❤️', colorHex: '#D85A30'),
  GoalOption(value: 'productivity', title: 'Be Productive', subtitle: 'Focus, plan and get things done.', icon: '💼', colorHex: '#378ADD'),
  GoalOption(value: 'overall', title: 'Something Else', subtitle: 'Create your own purpose.', icon: '✨', colorHex: '#1D9E75'),
];
