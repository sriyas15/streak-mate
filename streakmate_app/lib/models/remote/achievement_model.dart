/// achievement_model.dart
class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String condition;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int displayOrder;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.condition,
    required this.xpReward,
    required this.isUnlocked,
    this.unlockedAt,
    required this.displayOrder,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    // Handle both getAllAchievements (flat) and getUnlocked (populated ref)
    final inner = json['achievementId'];
    final data =
        (inner != null && inner is Map<String, dynamic>) ? inner : json;
    return AchievementModel(
      id: (data['_id'] ?? json['_id'] ?? '') as String,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? '🏆',
      condition: data['condition'] as String? ?? '',
      xpReward: data['xpReward'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
      displayOrder: data['displayOrder'] as int? ?? 0,
    );
  }

  /// Fallback client-side achievement definitions used for demo when
  /// the Achievement collection hasn't been seeded yet.
  static List<AchievementModel> get defaults => [
        const AchievementModel(
            id: 'a1', name: 'First Step', description: 'Complete your first habit', icon: '👣', condition: 'first_habit_complete', xpReward: 50, isUnlocked: false, displayOrder: 0),
        const AchievementModel(
            id: 'a2', name: '3-Day Streak', description: 'Maintain a 3-day streak', icon: '🔥', condition: 'streak_3', xpReward: 30, isUnlocked: false, displayOrder: 1),
        const AchievementModel(
            id: 'a3', name: 'Week Warrior', description: 'Hit a 7-day streak', icon: '⚔️', condition: 'streak_7', xpReward: 100, isUnlocked: false, displayOrder: 2),
        const AchievementModel(
            id: 'a4', name: 'Fortnight Fighter', description: '14-day streak', icon: '🛡️', condition: 'streak_14', xpReward: 150, isUnlocked: false, displayOrder: 3),
        const AchievementModel(
            id: 'a5', name: 'Three Weeks Strong', description: '21-day streak', icon: '💪', condition: 'streak_21', xpReward: 200, isUnlocked: false, displayOrder: 4),
        const AchievementModel(
            id: 'a6', name: 'Month Master', description: '30-day streak', icon: '👑', condition: 'streak_30', xpReward: 300, isUnlocked: false, displayOrder: 5),
        const AchievementModel(
            id: 'a7', name: 'Half Century', description: '50-day streak', icon: '💎', condition: 'streak_50', xpReward: 500, isUnlocked: false, displayOrder: 6),
        const AchievementModel(
            id: 'a8', name: 'Century Club', description: '100-day streak', icon: '🚀', condition: 'streak_100', xpReward: 1000, isUnlocked: false, displayOrder: 7),
        const AchievementModel(
            id: 'a9', name: 'Perfect Week', description: 'All habits done every day for a week', icon: '✨', condition: 'perfect_week', xpReward: 200, isUnlocked: false, displayOrder: 8),
        const AchievementModel(
            id: 'a10', name: 'Social Butterfly', description: 'Add 5 friends', icon: '🦋', condition: 'add_5_friends', xpReward: 100, isUnlocked: false, displayOrder: 9),
        const AchievementModel(
            id: 'a11', name: 'Motivator', description: 'Nudge a friend', icon: '👊', condition: 'nudge_sent', xpReward: 5, isUnlocked: false, displayOrder: 10),
        const AchievementModel(
            id: 'a12', name: 'Year of Wins', description: '365-day streak', icon: '🌟', condition: 'streak_365', xpReward: 5000, isUnlocked: false, displayOrder: 11),
      ];
}