import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../repositories/freeze_repository.dart';
import 'auth_provider.dart';

/// freeze_provider.dart
/// Drives FreezeDaysScreen activation buttons and keeps authProvider's
/// user freeze/cheat counts in sync after activation.

class FreezeState {
  final bool loading;
  final bool activating; // true while a freeze/cheat POST is in-flight
  final FreezeBalance? balance;
  final String? error;
  final String? successMessage;

  const FreezeState({
    this.loading = false,
    this.activating = false,
    this.balance,
    this.error,
    this.successMessage,
  });

  FreezeState copyWith({
    bool? loading,
    bool? activating,
    FreezeBalance? balance,
    String? error,
    String? successMessage,
  }) {
    return FreezeState(
      loading: loading ?? this.loading,
      activating: activating ?? this.activating,
      balance: balance ?? this.balance,
      error: error,
      successMessage: successMessage,
    );
  }
}

class FreezeNotifier extends StateNotifier<FreezeState> {
  FreezeNotifier(this._repo, this._ref) : super(const FreezeState());

  final FreezeRepository _repo;
  final Ref _ref;

  Future<void> loadBalance() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final balance = await _repo.getBalance();
      state = state.copyWith(loading: false, balance: balance);
    } on ApiException catch (e) {
      debugPrint('[Freeze] loadBalance failed: ${e.message}');
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  /// Activates a freeze for [date] (defaults to today, "YYYY-MM-DD").
  Future<bool> activateFreeze({String? date, String? reason}) async {
    if (state.activating) return false;
    state = state.copyWith(activating: true, error: null, successMessage: null);
    try {
      final balance = await _repo.activateFreeze(
        date: date ?? _today(),
        reason: reason,
      );
      state = state.copyWith(
        activating: false,
        balance: balance,
        successMessage: 'Streak freeze activated ❄️',
      );
      _syncAuthUser(balance);
      return true;
    } on ApiException catch (e) {
      debugPrint('[Freeze] activateFreeze failed: ${e.message}');
      state = state.copyWith(activating: false, error: e.message);
      return false;
    }
  }

  /// Activates a cheat day for [date] (defaults to today).
  Future<bool> activateCheatDay({String? date}) async {
    if (state.activating) return false;
    state = state.copyWith(activating: true, error: null, successMessage: null);
    try {
      final balance = await _repo.activateCheatDay(date: date ?? _today());
      state = state.copyWith(
        activating: false,
        balance: balance,
        successMessage: "Cheat day used. Don't make it a habit 😏",
      );
      _syncAuthUser(balance);
      return true;
    } on ApiException catch (e) {
      debugPrint('[Freeze] activateCheatDay failed: ${e.message}');
      state = state.copyWith(activating: false, error: e.message);
      return false;
    }
  }

  void _syncAuthUser(FreezeBalance balance) {
    // Keep authProvider's user counts in sync so other screens
    // (profile, freeze card on home) reflect the new balance instantly.
    _ref.read(authProvider.notifier).updateFreezeBalance(
          freezesRemaining: balance.freezesRemaining,
          freezesUsed: balance.freezesUsed,
          cheatDaysRemaining: balance.cheatDaysRemaining,
          cheatDaysUsed: balance.cheatDaysUsed,
        );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void clearMessages() => state = state.copyWith(error: null, successMessage: null);
}

final freezeRepositoryProvider =
    Provider<FreezeRepository>((ref) => FreezeRepository());

final freezeProvider =
    StateNotifierProvider<FreezeNotifier, FreezeState>((ref) {
  return FreezeNotifier(ref.watch(freezeRepositoryProvider), ref);
});