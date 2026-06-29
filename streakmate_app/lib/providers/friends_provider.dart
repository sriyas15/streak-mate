import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/friends_model.dart';
import '../repositories/friends_repository.dart';
import '../repositories/leaderboard_repository.dart';

class FriendsState {
  final List<FriendModel> friends;
  final List<FriendRequestModel> incomingRequests;
  final List<FriendModel> suggestions;
  final List<LeaderboardEntry> leaderboard;
  final List<FriendActivityItem> activity;
  final List<FriendModel> searchResults;
  final bool loading;
  final bool searchLoading;
  final String? error;
  final String? successMessage;

  const FriendsState({
    this.friends = const [],
    this.incomingRequests = const [],
    this.suggestions = const [],
    this.leaderboard = const [],
    this.activity = const [],
    this.searchResults = const [],
    this.loading = false,
    this.searchLoading = false,
    this.error,
    this.successMessage,
  });

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendRequestModel>? incomingRequests,
    List<FriendModel>? suggestions,
    List<LeaderboardEntry>? leaderboard,
    List<FriendActivityItem>? activity,
    List<FriendModel>? searchResults,
    bool? loading,
    bool? searchLoading,
    String? error,
    String? successMessage,
  }) =>
      FriendsState(
        friends: friends ?? this.friends,
        incomingRequests: incomingRequests ?? this.incomingRequests,
        suggestions: suggestions ?? this.suggestions,
        leaderboard: leaderboard ?? this.leaderboard,
        activity: activity ?? this.activity,
        searchResults: searchResults ?? this.searchResults,
        loading: loading ?? this.loading,
        searchLoading: searchLoading ?? this.searchLoading,
        error: error,
        successMessage: successMessage,
      );
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier(this._friends, this._leaderboard)
      : super(const FriendsState());

  final FriendsRepository _friends;
  final LeaderboardRepository _leaderboard;

  Future<void> loadAll() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _friends.getFriends(),
        _friends.getIncomingRequests(),
        _friends.getSuggestions(),
        _leaderboard.getFriendsLeaderboard(),
        _friends.getActivity(),
      ]);
      state = state.copyWith(
        loading: false,
        friends: results[0] as List<FriendModel>,
        incomingRequests: results[1] as List<FriendRequestModel>,
        suggestions: results[2] as List<FriendModel>,
        leaderboard: results[3] as List<LeaderboardEntry>,
        activity: results[4] as List<FriendActivityItem>,
      );
    } on ApiException catch (e) {
      debugPrint('[Friends] loadAll error: ${e.message}');
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      debugPrint('[Friends] loadAll unexpected: $e');
      state = state.copyWith(
          loading: false, error: 'Could not load friends');
    }
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = state.copyWith(searchResults: []);
      return;
    }
    state = state.copyWith(searchLoading: true);
    try {
      final results = await _friends.searchUsers(query.trim());
      state = state.copyWith(searchLoading: false, searchResults: results);
    } on ApiException catch (e) {
      state = state.copyWith(searchLoading: false, error: e.message);
    }
  }

  void clearSearch() => state = state.copyWith(searchResults: []);

  Future<void> sendRequest(String userId) async {
    try {
      await _friends.sendRequest(userId);
      // Update search results and suggestions optimistically
      state = state.copyWith(
        suggestions:
            state.suggestions.where((s) => s.id != userId).toList(),
        searchResults: state.searchResults.map((u) {
          if (u.id != userId) return u;
          return FriendModel(
            id: u.id, name: u.name, username: u.username,
            profilePicture: u.profilePicture,
            currentStreakDays: u.currentStreakDays,
            bestStreakDays: u.bestStreakDays,
            level: u.level,
            isFriend: false, requestSent: true,
          );
        }).toList(),
        successMessage: 'Friend request sent!',
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> acceptRequest(String senderId) async {
    try {
      await _friends.acceptRequest(senderId);
      final accepted = state.incomingRequests
          .firstWhere((r) => r.sender.id == senderId);
      state = state.copyWith(
        incomingRequests: state.incomingRequests
            .where((r) => r.sender.id != senderId)
            .toList(),
        friends: [...state.friends, accepted.sender],
        successMessage: 'Friend added! 🎉',
      );
      // Refresh leaderboard
      final lb = await _leaderboard.getFriendsLeaderboard();
      state = state.copyWith(leaderboard: lb);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> rejectRequest(String senderId) async {
    try {
      await _friends.rejectRequest(senderId);
      state = state.copyWith(
        incomingRequests: state.incomingRequests
            .where((r) => r.sender.id != senderId)
            .toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> nudge(String userId) async {
    try {
      await _friends.nudgeFriend(userId);
      state = state.copyWith(successMessage: 'Nudge sent 👊');
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> removeFriend(String userId) async {
    try {
      await _friends.removeFriend(userId);
      state = state.copyWith(
        friends: state.friends.where((f) => f.id != userId).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void clearMessages() =>
      state = state.copyWith(error: null, successMessage: null);
}

final friendsRepositoryProvider =
    Provider<FriendsRepository>((ref) => FriendsRepository());
final leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((ref) => LeaderboardRepository());

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier(
    ref.watch(friendsRepositoryProvider),
    ref.watch(leaderboardRepositoryProvider),
  );
});
