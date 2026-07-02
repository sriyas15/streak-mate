import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../models/remote/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
            () => ref.read(notificationInboxProvider.notifier).load());
  }

  void _onTap(NotificationModel notif) {
    // Mark as read
    ref.read(notificationInboxProvider.notifier).markRead(notif.id);
    // Navigate based on type
    _navigate(notif);
  }

  void _navigate(NotificationModel notif) {
    switch (notif.type) {
      case 'habit_reminder':
      case 'daily_reminder':
      case 'streak_warning':
      case 'streak_at_risk':
      case 'streak_broken':
      case 'streak_restored':
      case 'end_of_day_nudge':
      case 'funny_morning':
      case 'funny_inactive':
      case 'funny_almost_done':
      case 'funny_perfect_day':
      case 'funny_late_night':
      case 'funny_relapse':
        context.pop();
        // Home is already showing — just pop back
        break;

      case 'achievement_unlocked':
      case 'level_up':
      case 'xp_earned':
        context.pop();
        context.push(RouteNames.profileAchievements);
        break;

      case 'friend_request':
      case 'friend_accepted':
      case 'friend_nudge':
      case 'friend_streak_overtake':
        context.pop();
        // Friends is a tab in HomeScreen — handled by HomeScreen index
        break;

      // case 'leaderboard_change':
      //   context.pop();
      //   context.push(RouteNames.leaderboard);
      //   break;

      case 'weekly_summary':
      case 'monthly_report':
        context.pop();
        context.push(RouteNames.profileInsights);
        break;

      case 'freeze_used':
      case 'cheat_day_used':
      case 'freeze_running_low':
        context.pop();
        context.push(RouteNames.profileFreeze);
        break;

      default:
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationInboxProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.darkTextPrimary),
        ),
        title: Text('Notifications', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          if (state.items.any((n) => n.isUnread))
            TextButton(
              onPressed: () =>
                  ref.read(notificationInboxProvider.notifier).markAllRead(),
              child: Text('Mark all read',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.prayerPurple)),
            ),
        ],
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.prayerPurple))
          : state.items.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
        color: AppColors.prayerPurple,
        backgroundColor: AppColors.darkSurface,
        onRefresh: () =>
            ref.read(notificationInboxProvider.notifier).load(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount:
          state.items.length + (state.hasMore ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == state.items.length) {
              // Load more trigger
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(notificationInboxProvider.notifier)
                    .loadMore();
              });
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.prayerPurple,
                      strokeWidth: 2),
                ),
              );
            }
            final notif = state.items[i];
            return _NotificationTile(
              notif: notif,
              onTap: () => _onTap(notif),
              onDismiss: () => ref
                  .read(notificationInboxProvider.notifier)
                  .delete(notif.id),
            );
          },
        ),
      ),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger.withOpacity(0.15),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isUnread
                ? AppColors.prayerPurple.withOpacity(0.07)
                : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isUnread
                  ? AppColors.prayerPurple.withOpacity(0.25)
                  : AppColors.darkBorder,
              width: notif.isUnread ? 1 : 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(notif.emoji,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title,
                        style: AppTextStyles.labelLg.copyWith(
                          color: notif.isUnread
                              ? AppColors.darkTextPrimary
                              : AppColors.darkTextSecondary,
                        )),
                    const SizedBox(height: 3),
                    Text(notif.body,
                        style: AppTextStyles.bodySm,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      timeago.format(notif.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (notif.isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.prayerPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('All caught up!', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            "No notifications yet.\nWe'll let you know when something happens.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd,
          ),
        ],
      ),
    );
  }
}