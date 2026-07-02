import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/remote/notification_model.dart';

// ─── Unread count ─────────────────────────────────────────────────────────────
class UnreadCountNotifier extends StateNotifier<int> {
  final Ref _ref;
  UnreadCountNotifier(this._ref) : super(0);

  Future<void> fetch() async {
    try {
      final dio = _ref.read(dioClientProvider);
      final res = await dio.get(ApiEndpoints.unreadCount);
      state = res.data['data']['count'] ?? 0;
    } catch (_) {}
  }

  void increment() => state = state + 1;

  void reset() => state = 0;
}

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref),
);

// ─── Notification inbox ───────────────────────────────────────────────────────
class NotificationInboxState {
  final List<NotificationModel> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const NotificationInboxState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  NotificationInboxState copyWith({
    List<NotificationModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      NotificationInboxState(
        items:     items     ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore:   hasMore   ?? this.hasMore,
        page:      page      ?? this.page,
        error:     error,
      );
}

class NotificationInboxNotifier
    extends StateNotifier<NotificationInboxState> {
  final Ref _ref;
  NotificationInboxNotifier(this._ref)
      : super(const NotificationInboxState());

  // ── Fetch first page ────────────────────────────────────────────
  Future<void> load() async {
    state = state.copyWith(isLoading: true, page: 1);
    try {
      final dio = _ref.read(dioClientProvider);
      final res = await dio.get(
        ApiEndpoints.notificationsList,
        queryParameters: {'page': 1, 'limit': 20},
      );
      final list = (res.data['data']['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      final total = res.data['data']['total'] ?? 0;

      state = state.copyWith(
        items:     list,
        isLoading: false,
        hasMore:   list.length < total,
        page:      2,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load notifications');
    }
  }

  // ── Load more (pagination) ──────────────────────────────────────
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final dio = _ref.read(dioClientProvider);
      final res = await dio.get(
        ApiEndpoints.notificationsList,
        queryParameters: {'page': state.page, 'limit': 20},
      );
      final list = (res.data['data']['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      final total = res.data['data']['total'] ?? 0;

      state = state.copyWith(
        items:     [...state.items, ...list],
        isLoading: false,
        hasMore:   state.items.length + list.length < total,
        page:      state.page + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Mark single as read ─────────────────────────────────────────
  Future<void> markRead(String notificationId) async {
    // Optimistic update
    state = state.copyWith(
      items: state.items.map((n) {
        if (n.id == notificationId) {
          return NotificationModel.fromJson({
            '_id': n.id, 'userId': n.userId, 'type': n.type,
            'title': n.title, 'body': n.body, 'isSeen': true,
            'isRead': true, 'createdAt': n.createdAt.toIso8601String(),
          });
        }
        return n;
      }).toList(),
    );

    try {
      final dio = _ref.read(dioClientProvider);
      await dio.patch(ApiEndpoints.markNotifRead(notificationId));
      // Refresh unread count
      _ref.read(unreadCountProvider.notifier).fetch();
    } catch (_) {}
  }

  // ── Mark all as read ────────────────────────────────────────────
  Future<void> markAllRead() async {
    state = state.copyWith(
      items: state.items.map((n) => NotificationModel.fromJson({
        '_id': n.id, 'userId': n.userId, 'type': n.type,
        'title': n.title, 'body': n.body, 'isSeen': true,
        'isRead': true, 'createdAt': n.createdAt.toIso8601String(),
      })).toList(),
    );

    try {
      final dio = _ref.read(dioClientProvider);
      await dio.patch(ApiEndpoints.readAll);
      _ref.read(unreadCountProvider.notifier).reset();
    } catch (_) {}
  }

  // ── Delete single ───────────────────────────────────────────────
  Future<void> delete(String notificationId) async {
    state = state.copyWith(
      items: state.items.where((n) => n.id != notificationId).toList(),
    );
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.delete(ApiEndpoints.deleteNotif(notificationId));
      _ref.read(unreadCountProvider.notifier).fetch();
    } catch (_) {}
  }

  // ── Clear all ───────────────────────────────────────────────────
  Future<void> clearAll() async {
    state = const NotificationInboxState(items: []);
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.delete(ApiEndpoints.clearAll);
      _ref.read(unreadCountProvider.notifier).reset();
    } catch (_) {}
  }

  // ── Add incoming foreground notification to top of list ─────────
  void addIncoming(NotificationModel notif) {
    state = state.copyWith(items: [notif, ...state.items]);
    _ref.read(unreadCountProvider.notifier).increment();
  }
}

final notificationInboxProvider = StateNotifierProvider<
    NotificationInboxNotifier, NotificationInboxState>(
  (ref) => NotificationInboxNotifier(ref),
);