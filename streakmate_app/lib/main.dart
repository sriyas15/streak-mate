import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/fcm_service.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/theme/dark_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Register background message handler before runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: StreakMateApp(),
    ),
  );
}

class StreakMateApp extends ConsumerStatefulWidget {
  const StreakMateApp({super.key});

  @override
  ConsumerState<StreakMateApp> createState() => _StreakMateAppState();
}

class _StreakMateAppState extends ConsumerState<StreakMateApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFCM();
    });
  }

  Future<void> _initFCM() async {
    final authState = ref.read(authProvider);

    // Only init FCM when user is logged in
    if (authState.status != AuthStatus.authenticated) {
      // Listen for auth changes and init FCM after login
      ref.listenManual(authProvider, (previous, next) {
        if (next.status == AuthStatus.authenticated &&
            previous?.status != AuthStatus.authenticated) {
          _setupFCM();
        }
      });
      return;
    }

    await _setupFCM();
  }

  Future<void> _setupFCM() async {
    final dio = ref.read(dioClientProvider);

    // Init FCM — registers token, sets up handlers
    await FCMService.instance.init(dio: dio);

    // Fetch initial unread count
    ref.read(unreadCountProvider.notifier).fetch();

    // Handle notification tap → navigate to correct screen
    FCMService.instance.setOnNotificationTap((String type) {
      _handleNotificationTap(type);
    });

    // Handle new foreground notification → increment badge
    FCMService.instance.setOnNewNotification((message) {
      ref.read(unreadCountProvider.notifier).increment();
    });

    // Handle notification that opened app from terminated state
    final pending = FCMService.instance.consumePendingMessage();
    if (pending != null) {
      final type = pending.data['type'] ?? '';
      // Small delay to ensure router is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _handleNotificationTap(type);
    }
  }

  void _handleNotificationTap(String type) {
    final router = ref.read(routerProvider);

    switch (type) {
      case 'achievement_unlocked':
      case 'level_up':
      case 'xp_earned':
        router.push(RouteNames.profileAchievements);
        break;

      // case 'leaderboard_change':
      // case 'friend_streak_overtake':
      //   router.push(RouteNames.leaderboard);
      //   break;

      case 'weekly_summary':
      case 'monthly_report':
        router.push(RouteNames.profileInsights);
        break;

      case 'freeze_used':
      case 'cheat_day_used':
      case 'freeze_running_low':
        router.push(RouteNames.profileFreeze);
        break;

      // Everything else → notifications screen
      default:
        router.push(RouteNames.notifications);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StreakMate',
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'app.dart';
//
// // TODO(you): if wiring flutter_dotenv, do it here before runApp:
// //   import 'package:flutter_dotenv/flutter_dotenv.dart';
// //   await dotenv.load(fileName: ".env");
//
// void main() {
//   runApp(const ProviderScope(child: StreakMateApp()));
// }