/// api_endpoints.dart
/// All endpoint paths, relative to API base URL.
/// Base URL itself comes from env — see dio_client.dart.
///
/// HOW TO WIRE YOUR ENV:
///   Option A) flutter_dotenv package:
///     1. Add `flutter_dotenv` to pubspec.yaml
///     2. Create a `.env` file at project root:  API_BASE_URL=https://your-api.com/api/v1
///     3. In main.dart:  await dotenv.load(fileName: ".env");
///     4. In dio_client.dart, replace the TODO with: dotenv.env['API_BASE_URL']
///
///   Option B) --dart-define:
///     flutter run --dart-define=API_BASE_URL=https://your-api.com/api/v1
///     (dio_client.dart already reads this via String.fromEnvironment)
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ───────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';

  // ─── Onboarding ─────────────────────────────────────────────────────────
  static const String onboardingStatus = '/onboarding/status';
  static const String onboardingGoal = '/onboarding/goal';
  static const String onboardingHabits = '/onboarding/habits';
  static const String onboardingSubtasks = '/onboarding/subtasks';
  static const String onboardingReminders = '/onboarding/reminders';
  static const String onboardingComplete = '/onboarding/complete';

  // ─── Habits ─────────────────────────────────────────────────────────────
  static const String habits = '/habits';
  static const String habitTemplates = '/habits/templates';
  static const String habitsToday = '/habits/today';
  static String habitById(String id) => '/habits/$id';
  static String habitSubtasks(String habitId) => '/habits/$habitId/subtasks';
  static String subtaskById(String habitId, String subtaskId) =>
      '/habits/$habitId/subtasks/$subtaskId';

  // ─── Habit Logs ─────────────────────────────────────────────────────────
  static String habitLogs(String habitId) => '/habits/$habitId/logs';
  static String habitLogByDate(String habitId, String date) =>
      '/habits/$habitId/logs/$date';
  static String habitLogComplete(String habitId, String date) =>
      '/habits/$habitId/logs/$date/complete';
  static String habitLogUncomplete(String habitId, String date) =>
      '/habits/$habitId/logs/$date/uncomplete';
  static String habitLogSubtask(String habitId, String date, String subtaskId) =>
      '/habits/$habitId/logs/$date/subtasks/$subtaskId';
}