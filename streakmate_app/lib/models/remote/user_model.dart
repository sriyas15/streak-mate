/// user_model.dart
/// Mirrors the sanitized User object returned by authService.sanitizeUser()
/// (password/refreshToken/verification & reset tokens are stripped server-side).
class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profilePicture;
  final String? bio;
  final String timezone;

  // Onboarding
  final bool onboardingCompleted;
  final int onboardingStep;
  final String? selectedGoal;

  // Streak meta
  final int currentStreakDays;
  final int bestStreakDays;
  final String? lastProductiveDate;

  // Gamification — present in payload but unused during auth/onboarding flows
  final int level;
  final int xpPoints;
  final int xpToNextLevel;

  // Freeze & cheat day
  final int totalFreezesAlloted;
  final int freezesUsed;
  final int freezesRemaining;
  final int cheatDaysAlloted;
  final int cheatDaysUsed;
  final int cheatDaysRemaining;

  // Auth
  final String authProvider;
  final bool isEmailVerified;

  // Settings
  final bool notificationsEnabled;
  final String theme;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profilePicture,
    this.bio,
    required this.timezone,
    required this.onboardingCompleted,
    required this.onboardingStep,
    this.selectedGoal,
    required this.currentStreakDays,
    required this.bestStreakDays,
    this.lastProductiveDate,
    required this.level,
    required this.xpPoints,
    required this.xpToNextLevel,
    required this.totalFreezesAlloted,
    required this.freezesUsed,
    required this.freezesRemaining,
    required this.cheatDaysAlloted,
    required this.cheatDaysUsed,
    required this.cheatDaysRemaining,
    required this.authProvider,
    required this.isEmailVerified,
    required this.notificationsEnabled,
    required this.theme,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePicture: json['profilePicture'] as String?,
      bio: json['bio'] as String?,
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as int? ?? 1,
      selectedGoal: json['selectedGoal'] as String?,
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      bestStreakDays: json['bestStreakDays'] as int? ?? 0,
      lastProductiveDate: json['lastProductiveDate'] as String?,
      level: json['level'] as int? ?? 1,
      xpPoints: json['xpPoints'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      totalFreezesAlloted: json['totalFreezesAlloted'] as int? ?? 3,
      freezesUsed: json['freezesUsed'] as int? ?? 0,
      freezesRemaining: json['freezesRemaining'] as int? ?? 3,
      cheatDaysAlloted: json['cheatDaysAlloted'] as int? ?? 2,
      cheatDaysUsed: json['cheatDaysUsed'] as int? ?? 0,
      cheatDaysRemaining: json['cheatDaysRemaining'] as int? ?? 2,
      authProvider: json['authProvider'] as String? ?? 'email',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'dark',
    );
  }

  UserModel copyWith({
    bool? onboardingCompleted,
    int? onboardingStep,
    String? selectedGoal,
  }) {
    return UserModel(
      id: id,
      name: name,
      username: username,
      email: email,
      profilePicture: profilePicture,
      bio: bio,
      timezone: timezone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      currentStreakDays: currentStreakDays,
      bestStreakDays: bestStreakDays,
      lastProductiveDate: lastProductiveDate,
      level: level,
      xpPoints: xpPoints,
      xpToNextLevel: xpToNextLevel,
      totalFreezesAlloted: totalFreezesAlloted,
      freezesUsed: freezesUsed,
      freezesRemaining: freezesRemaining,
      cheatDaysAlloted: cheatDaysAlloted,
      cheatDaysUsed: cheatDaysUsed,
      cheatDaysRemaining: cheatDaysRemaining,
      authProvider: authProvider,
      isEmailVerified: isEmailVerified,
      notificationsEnabled: notificationsEnabled,
      theme: theme,
    );
  }
}