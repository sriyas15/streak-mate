/**
 * constants.js
 * App-wide constants — single source of truth
 */

// ─── Habit categories ────────────────────────────────────────────────────────
export const HABIT_CATEGORIES = {
  GYM: 'gym',
  PRAYER: 'prayer',
  STUDY: 'study',
  DIET: 'diet',
  WELFARE: 'welfare',
  CUSTOM: 'custom',
}

// ─── Subtask input types ──────────────────────────────────────────────────────
export const INPUT_TYPES = {
  CHECKBOX: 'checkbox',
  QUANTITY: 'quantity',
  TIMER: 'timer',
}

// ─── Completion rules ─────────────────────────────────────────────────────────
export const COMPLETION_RULES = {
  ALL_REQUIRED: 'all_required',
  PERCENTAGE: 'percentage',
  USER_DEFINED: 'user_defined',
}

// ─── Streak milestones ────────────────────────────────────────────────────────
export const STREAK_MILESTONES = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365]

// ─── Monthly defaults ────────────────────────────────────────────────────────
export const DEFAULT_FREEZES_PER_MONTH = 3
export const DEFAULT_CHEAT_DAYS_PER_MONTH = 2
export const MAX_HABITS_PER_USER = 10

// ─── Habit templates (seeded into AppConfig) ─────────────────────────────────
export const HABIT_TEMPLATES = [
  {
    category: 'gym',
    name: 'Gym / Workout',
    icon: '🏋️',
    color: '#E24B4A',
    subtasks: [
      { name: 'Warm-up', inputType: 'timer', unit: 'min', targetValue: 10, isRequired: true, displayOrder: 0 },
      { name: 'Main workout session', inputType: 'timer', unit: 'min', targetValue: 45, isRequired: true, displayOrder: 1 },
      { name: 'Cool-down / stretch', inputType: 'timer', unit: 'min', targetValue: 10, isRequired: true, displayOrder: 2 },
      { name: 'Post-workout protein', inputType: 'quantity', unit: 'g', targetValue: 40, isRequired: false, displayOrder: 3 },
    ],
  },
  {
    category: 'prayer',
    name: 'Prayer / Quran',
    icon: '🕌',
    color: '#7F77DD',
    subtasks: [
      { name: 'Fajr', inputType: 'checkbox', isRequired: true, displayOrder: 0 },
      { name: 'Dhuhr', inputType: 'checkbox', isRequired: true, displayOrder: 1 },
      { name: 'Asr', inputType: 'checkbox', isRequired: true, displayOrder: 2 },
      { name: 'Maghrib', inputType: 'checkbox', isRequired: true, displayOrder: 3 },
      { name: 'Isha', inputType: 'checkbox', isRequired: true, displayOrder: 4 },
      { name: 'Quran reading (min. 1 page)', inputType: 'count', unit: 'pages', targetValue: 1, isRequired: false, displayOrder: 5 },
      { name: 'Morning adhkar', inputType: 'checkbox', isRequired: false, displayOrder: 6 },
      { name: 'Evening adhkar', inputType: 'checkbox', isRequired: false, displayOrder: 7 },
      { name: 'Dua session', inputType: 'checkbox', isRequired: false, displayOrder: 8 },
      { name: 'Knowledge (lecture/article)', inputType: 'checkbox', isRequired: false, displayOrder: 9 },
      { name: 'Charity / Sadaqah', inputType: 'checkbox', isRequired: false, displayOrder: 10 },
    ],
  },
  {
    category: 'study',
    name: 'Study',
    icon: '📚',
    color: '#BA7517',
    subtasks: [
      { name: 'Study / deep work session', inputType: 'timer', unit: 'min', targetValue: 60, isRequired: true, displayOrder: 0 },
      { name: 'Assignment / task completed', inputType: 'checkbox', isRequired: true, displayOrder: 1 },
      { name: 'Notes revised', inputType: 'checkbox', isRequired: false, displayOrder: 2 },
      { name: 'Practice problems', inputType: 'quantity', unit: 'Qs', isRequired: false, displayOrder: 3 },
    ],
  },
  {
    category: 'diet',
    name: 'Diet / Nutrition',
    icon: '🥗',
    color: '#1D9E75',
    subtasks: [
      { name: 'No junk food', inputType: 'checkbox', isRequired: true, displayOrder: 0 },
      { name: 'Healthy meal eaten', inputType: 'checkbox', isRequired: true, displayOrder: 1 },
      { name: 'Calories / macros logged', inputType: 'quantity', unit: 'kcal', isRequired: false, displayOrder: 2 },
      { name: 'No late-night eating', inputType: 'checkbox', isRequired: false, displayOrder: 3 },
      { name: 'Supplements taken', inputType: 'checkbox', isRequired: false, displayOrder: 4 },
    ],
  },
  {
    category: 'welfare',
    name: 'Personal Welfare',
    icon: '🌿',
    color: '#185FA5',
    subtasks: [
      { name: 'Water intake', inputType: 'quantity', unit: 'ml', targetValue: 2000, isRequired: true, displayOrder: 0 },
      { name: 'Sleep (7+ hours)', inputType: 'quantity', unit: 'hrs', targetValue: 7, isRequired: true, displayOrder: 1 },
      { name: 'Family time (phone-free)', inputType: 'checkbox', isRequired: false, displayOrder: 2 },
      { name: 'Skincare / grooming', inputType: 'checkbox', isRequired: false, displayOrder: 3 },
      { name: 'Journaling / mood log', inputType: 'checkbox', isRequired: false, displayOrder: 4 },
    ],
  },
  {
    category: 'custom',
    name: 'Custom Habit',
    icon: '⭐',
    color: '#888780',
    subtasks: [],
  },
]

// ─── Achievement conditions ──────────────────────────────────────────────────
export const ACHIEVEMENT_CONDITIONS = [
  { condition: 'first_habit_complete', type: 'completion', xpReward: 50 },
  { condition: 'streak_3',   type: 'streak', conditionValue: 3,   xpReward: 30 },
  { condition: 'streak_7',   type: 'streak', conditionValue: 7,   xpReward: 100 },
  { condition: 'streak_14',  type: 'streak', conditionValue: 14,  xpReward: 150 },
  { condition: 'streak_21',  type: 'streak', conditionValue: 21,  xpReward: 200 },
  { condition: 'streak_30',  type: 'streak', conditionValue: 30,  xpReward: 300 },
  { condition: 'streak_50',  type: 'streak', conditionValue: 50,  xpReward: 500 },
  { condition: 'streak_100', type: 'streak', conditionValue: 100, xpReward: 1000 },
  { condition: 'streak_365', type: 'streak', conditionValue: 365, xpReward: 5000 },
  { condition: 'perfect_week', type: 'completion', xpReward: 200 },
  { condition: 'add_5_friends', type: 'social', xpReward: 100 },
  { condition: 'nudge_sent', type: 'social', xpReward: 5 },
]

// ─── App config keys (seeded into AppConfig collection) ──────────────────────
export const APP_CONFIG_DEFAULTS = [
  { key: 'default_freezes_per_month',    value: 3,     description: 'Streak freeze days per user per month' },
  { key: 'default_cheat_days_per_month', value: 2,     description: 'Cheat days per user per month' },
  { key: 'max_habits_per_user',          value: 10,    description: 'Max active habits a user can have' },
  { key: 'xp_per_productive_day',        value: 50,    description: 'XP awarded for a fully productive day' },
  { key: 'xp_per_habit_complete',        value: 10,    description: 'XP per individual habit completion' },
  { key: 'streak_warning_hour',          value: 21,    description: '24h hour to send streak warning (9PM)' },
  { key: 'end_of_day_resolve_hour',      value: 0,     description: '24h hour to resolve the day (midnight)' },
  { key: 'funny_notif_hour',             value: 11,    description: '24h hour to send funny notifications (11AM)' },
  { key: 'maintenance_mode',             value: false, description: 'Put app in maintenance mode' },
  { key: 'min_app_version_ios',          value: '1.0.0', description: 'Minimum required iOS app version' },
  { key: 'min_app_version_android',      value: '1.0.0', description: 'Minimum required Android app version' },
]

// ─── Sync action types ────────────────────────────────────────────────────────
export const SYNC_ACTION_TYPES = [
  'HABIT_COMPLETE',
  'HABIT_UNCOMPLETE',
  'SUBTASK_UPDATE',
  'MOOD_UPDATE',
  'NOTE_UPDATE',
]

// ─── Day status labels (for calendar) ────────────────────────────────────────
export const DAY_STATUS = {
  COMPLETED: 'completed',
  PARTIAL:   'partial',
  MISSED:    'missed',
  FREEZE:    'freeze',
  CHEAT:     'cheat',
  TODAY:     'today',
  FUTURE:    'future',
  NONE:      'none',
}