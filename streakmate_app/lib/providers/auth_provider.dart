import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage.dart';
import '../models/remote/user_model.dart';
import '../repositories/auth_repository.dart';

/// auth_provider.dart
/// Holds the current auth/session state for the whole app.
/// Screens read `authProvider` and call its methods; they never touch
/// AuthRepository or Dio directly.

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthRepository _repository;

  /// Called once on app start. If a token exists, validate it via /auth/me
  /// so we know whether onboarding is still pending.
  Future<void> _restoreSession() async {
    final hasSession = await SecureStorageService.instance.hasValidSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // Token invalid/expired and refresh already failed inside the
      // interceptor — drop back to unauthenticated.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    if (state.status == AuthStatus.authenticating) return; // guard double-tap
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repository.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );
      debugPrint('[Auth] Register success — user: ${user.email}');
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      debugPrint('[Auth] Register failed — ${e.statusCode}: ${e.message}');
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      debugPrint('[Auth] Register unexpected error — $e');
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Something went wrong. Please try again.');
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (state.status == AuthStatus.authenticating) return; // guard double-tap
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await _repository.login(email: email, password: password);
      debugPrint('[Auth] Login success — user: ${user.email}, onboarded: ${user.onboardingCompleted}');
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on ApiException catch (e) {
      debugPrint('[Auth] Login failed — ${e.statusCode}: ${e.message}');
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      debugPrint('[Auth] Login unexpected error — $e');
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Something went wrong. Please try again.');
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Call after each onboarding step completes server-side, so router
  /// guards relying on `user.onboardingStep` / `onboardingCompleted`
  /// stay in sync without a full /auth/me refetch.
  void updateUserOnboarding({
    bool? onboardingCompleted,
    int? onboardingStep,
    String? selectedGoal,
  }) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(
        onboardingCompleted: onboardingCompleted,
        onboardingStep: onboardingStep,
        selectedGoal: selectedGoal,
      ),
    );
  }

  void updateFreezeBalance({
    required int freezesRemaining,
    required int freezesUsed,
    required int cheatDaysRemaining,
    required int cheatDaysUsed,
  }) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(
        freezesRemaining: freezesRemaining,
        freezesUsed: freezesUsed,
        cheatDaysRemaining: cheatDaysRemaining,
        cheatDaysUsed: cheatDaysUsed,
      ),
    );
  }

  void updateStreak({required int currentStreakDays, required int bestStreakDays}) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(
        currentStreakDays: currentStreakDays,
        bestStreakDays: bestStreakDays,
      ),
    );
  }

  /// Called after a successful profile update so the UI reflects the
  /// new name/bio/username without needing a full /auth/me re-fetch.
  void setUser(UserModel user) {
    state = state.copyWith(status: AuthStatus.authenticated, user: user);
  }

  void updateXP({required int xpPoints, required int level}) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(
        xpPoints: xpPoints,
        level: level,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});