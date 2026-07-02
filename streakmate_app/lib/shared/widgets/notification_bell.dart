import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../providers/notification_provider.dart';
import '../../features/home/screens/home_screen.dart';

/// Drop-in bell icon with red dot badge.
/// Usage: const NotificationBell()
class NotificationBell extends ConsumerWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return GestureDetector(
      onTap: () => context.push(RouteNames.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: iconColor ?? Colors.white,
            size: iconSize,
          ),

          // Red badge — only shown when unread > 0
          if (unread > 0)
            Positioned(
              top: -4,
              right: -6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                constraints:
                const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.darkBg,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}