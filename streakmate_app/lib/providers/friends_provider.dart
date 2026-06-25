import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/friends_model.dart';
import '../repositories/friends_repository.dart';
import '../repositories/leaderboard_repository.dart';

// ─── Friends state ────────────────────────────────────────────────────────────
class FriendsState {
  final List<FriendModel> friends;
  final List<FriendRequestModel> incomingRequests;
  final List<FriendModel> suggestions;
  final List<LeaderboardEntry> leaderboard;
  final bool loading;
  final String? error;

  const FriendsState({
    this.friends = const [],
    this.incomingRequests = const [],
    this.suggestions = const [],
    this.leaderboard = const [],
    this.loading = false,
    this.error,
  });

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendRequestModel>? incomingRequests,
    List<FriendModel>? suggestions,
    List<LeaderboardEntry>? leaderboard,
    bool? loading,
    String? error,
  }) =>
      FriendsState(
        friends: friends ?? this.friends,
        incomingRequests: incomingRequests ?? this.incomingRequests,
        suggestions: suggestions ?? this.suggestions,
        leaderboard: leaderboard ?? this.leaderboard,
        loading: loading ?? this.loading,
        error: error,
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
      ]);
      state = state.copyWith(
        loading: false,
        friends: results[0] as List<FriendModel>,
        incomingRequests: results[1] as List<FriendRequestModel>,
        suggestions: results[2] as List<FriendModel>,
        leaderboard: results[3] as List<LeaderboardEntry>,
      );
    } on ApiException catch (e) {
      debugPrint('[Friends] loadAll failed: ${e.message}');
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      debugPrint('[Friends] loadAll error: $e');
      state = state.copyWith(loading: false, error: 'Could not load friends');
    }
  }

  Future<void> sendRequest(String userId) async {
    try {
      await _friends.sendRequest(userId);
      // Remove from suggestions
      state = state.copyWith(
        suggestions: state.suggestions.where((s) => s.id != userId).toList(),
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
        incomingRequests:
            state.incomingRequests.where((r) => r.sender.id != senderId).toList(),
        friends: [...state.friends, accepted.sender],
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
        incomingRequests:
            state.incomingRequests.where((r) => r.sender.id != senderId).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> nudge(String userId) async {
    try {
      await _friends.nudgeFriend(userId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void clearError() => state = state.copyWith(error: null);
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