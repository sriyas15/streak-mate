import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

class UserProfileState {
  final bool saving;
  final bool loadingSettings;
  final String? error;
  final String? successMessage;
  final Map<String, dynamic> settings;

  const UserProfileState({
    this.saving = false,
    this.loadingSettings = false,
    this.error,
    this.successMessage,
    this.settings = const {},
  });

  UserProfileState copyWith({
    bool? saving,
    bool? loadingSettings,
    String? error,
    String? successMessage,
    Map<String, dynamic>? settings,
  }) =>
      UserProfileState(
        saving: saving ?? this.saving,
        loadingSettings: loadingSettings ?? this.loadingSettings,
        error: error,
        successMessage: successMessage,
        settings: settings ?? this.settings,
      );
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier(this._repo, this._ref) : super(const UserProfileState());

  final UserRepository _repo;
  final Ref _ref;

  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? username,
  }) async {
    state = state.copyWith(saving: true, error: null, successMessage: null);
    try {
      final updated = await _repo.updateProfile(
          name: name, bio: bio, username: username);
      // Sync updated user back into authProvider
      _ref.read(authProvider.notifier).setUser(updated);
      state = state.copyWith(
          saving: false, successMessage: 'Profile updated successfully');
      return true;
    } on ApiException catch (e) {
      debugPrint('[UserProfile] updateProfile error: ${e.message}');
      state = state.copyWith(saving: false, error: e.message);
      return false;
    }
  }

  Future<void> loadSettings() async {
    state = state.copyWith(loadingSettings: true);
    try {
      final s = await _repo.getSettings();
      state = state.copyWith(loadingSettings: false, settings: s);
    } on ApiException catch (e) {
      state = state.copyWith(loadingSettings: false, error: e.message);
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    state = state.copyWith(saving: true, error: null);
    try {
      final s = await _repo.updateSettings(updates);
      state = state.copyWith(
          saving: false,
          settings: s,
          successMessage: 'Settings saved');
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(saving: true, error: null);
    try {
      await _repo.deleteAccount();
      await _ref.read(authProvider.notifier).logout();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
      return false;
    }
  }

  void clearMessages() =>
      state = state.copyWith(error: null, successMessage: null);
}

final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier(
      ref.watch(userRepositoryProvider), ref);
});