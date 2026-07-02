class NotificationModel {
  final String id;
  final String userId;
  final String? habitId;
  final String? triggeredByUserId;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? deepLinkScreen;
  final Map<String, dynamic>? deepLinkParams;
  final bool isSeen;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.habitId,
    this.triggeredByUserId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.deepLinkScreen,
    this.deepLinkParams,
    this.isSeen = false,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id:                 j['_id'] ?? j['id'] ?? '',
        userId:             j['userId'] ?? '',
        habitId:            j['habitId'],
        triggeredByUserId:  j['triggeredByUserId'],
        type:               j['type'] ?? '',
        title:              j['title'] ?? '',
        body:               j['body'] ?? '',
        imageUrl:           j['imageUrl'],
        deepLinkScreen:     j['deepLinkScreen'],
        deepLinkParams:     j['deepLinkParams'] != null
            ? Map<String, dynamic>.from(j['deepLinkParams'])
            : null,
        isSeen:  j['isSeen'] ?? false,
        isRead:  j['isRead'] ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );

  // ── Helpers ──────────────────────────────────────────────────────
  bool get isUnread => !isRead;

  String get emoji {
    switch (type) {
      case 'streak_milestone':
      case 'streak_at_risk':
      case 'streak_broken':
      case 'streak_restored':
        return '🔥';
      case 'habit_reminder':
      case 'daily_reminder':
      case 'end_of_day_nudge':
        return '⏰';
      case 'freeze_used':
      case 'freeze_running_low':
        return '❄️';
      case 'cheat_day_used':
        return '😏';
      case 'achievement_unlocked':
        return '🏆';
      case 'level_up':
      case 'xp_earned':
        return '⭐';
      case 'friend_request':
      case 'friend_accepted':
        return '👥';
      case 'friend_nudge':
        return '👊';
      case 'friend_streak_overtake':
      case 'leaderboard_change':
        return '📊';
      case 'weekly_summary':
      case 'monthly_report':
        return '📅';
      case 'funny_morning':
      case 'funny_inactive':
      case 'funny_perfect_day':
      case 'funny_almost_done':
      case 'funny_late_night':
      case 'funny_relapse':
        return '😄';
      default:
        return '🔔';
    }
  }
}