/// friends_model.dart
class FriendModel {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;
  final int currentStreakDays;
  final int bestStreakDays;
  final int level;

  const FriendModel({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.level,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        id: (json['_id'] ?? json['userId'] ?? '') as String,
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        profilePicture: json['profilePicture'] as String?,
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        bestStreakDays: json['bestStreakDays'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class FriendRequestModel {
  final String id;
  final FriendModel sender;
  final String status;
  final DateTime sentAt;

  const FriendRequestModel({
    required this.id,
    required this.sender,
    required this.status,
    required this.sentAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      FriendRequestModel(
        id: json['_id'] as String? ?? '',
        sender: FriendModel.fromJson(
            json['senderId'] as Map<String, dynamic>? ?? {}),
        status: json['status'] as String? ?? 'pending',
        sentAt: json['sentAt'] != null
            ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String username;
  final String? profilePicture;
  final int currentStreak;
  final int bestStreak;
  final int level;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.username,
    this.profilePicture,
    required this.currentStreak,
    required this.bestStreak,
    required this.level,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        userId: (json['userId'] ?? '') as String,
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        profilePicture: json['profilePicture'] as String?,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        isMe: json['isMe'] as bool? ?? false,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}