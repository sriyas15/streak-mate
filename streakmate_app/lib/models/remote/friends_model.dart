/// friends_model.dart

class FriendModel {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;
  final int currentStreakDays;
  final int bestStreakDays;
  final int level;
  // Extra fields returned by search
  final bool isFriend;
  final bool requestSent;

  const FriendModel({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.level,
    this.isFriend = false,
    this.requestSent = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        id: (json['_id'] ?? json['userId'] ?? '') as String,
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        profilePicture: json['profilePicture'] as String?,
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        bestStreakDays: json['bestStreakDays'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        isFriend: json['isFriend'] as bool? ?? false,
        requestSent: json['requestSent'] as bool? ?? false,
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

/// Activity feed item from GET /friends/activity
class FriendActivityItem {
  final String id;
  final String friendName;
  final String friendUsername;
  final String? friendPicture;
  final String habitName;
  final String habitIcon;
  final DateTime completedAt;

  const FriendActivityItem({
    required this.id,
    required this.friendName,
    required this.friendUsername,
    this.friendPicture,
    required this.habitName,
    required this.habitIcon,
    required this.completedAt,
  });

  factory FriendActivityItem.fromJson(Map<String, dynamic> json) {
    // userId and habitId are populated objects from .populate()
    final user = json['userId'];
    final habit = json['habitId'];
    final name = user is Map ? (user['name'] as String? ?? '') : '';
    final username = user is Map ? (user['username'] as String? ?? '') : '';
    final picture = user is Map ? user['profilePicture'] as String? : null;
    final hName = habit is Map ? (habit['name'] as String? ?? '') : '';
    final hIcon = habit is Map ? (habit['icon'] as String? ?? '⭐') : '⭐';

    return FriendActivityItem(
      id: json['_id'] as String? ?? '',
      friendName: name,
      friendUsername: username,
      friendPicture: picture,
      habitName: hName,
      habitIcon: hIcon,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(completedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get initials {
    final parts = friendName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return friendName.isNotEmpty ? friendName[0].toUpperCase() : '?';
  }
}
