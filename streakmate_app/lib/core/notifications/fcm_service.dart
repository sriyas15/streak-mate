import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../network/api_endpoints.dart';
import '../storage/secure_storage.dart';

// ─── Background message handler (must be top-level function) ─────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App is in background/terminated — Flutter engine not running
  // Just log; local notification shown automatically by FCM
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final _messaging = FirebaseMessaging.instance;

  final _localNotif = FlutterLocalNotificationsPlugin();

  // Android notification channel — must match backend clickAction
  static const _androidChannel = AndroidNotificationChannel(
    'streakmate_high',
    'StreakMate Notifications',
    description: 'Habit reminders, streak alerts and achievements',
    importance: Importance.high,
    playSound: true,
  );

  // Called once from main.dart after Firebase.initializeApp()
  Future<void> init({required Dio dio}) async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (Android 13+ and iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] User denied notifications');
      return;
    }

    // 3. Set up local notifications for foreground display
    await _initLocalNotifications();

    // 4. Register token with backend
    await registerToken(dio: dio);

    // 5. Token refresh listener — re-register when token rotates
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed');
      registerToken(dio: dio, token: newToken);
    });

    // 6. Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. Check if app was opened from a terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] App opened from terminated via notification');
      // Store for router to handle after app is ready
      _pendingMessage = initial;
    }
  }

  // Pending message from terminated state — router reads this after first frame
  RemoteMessage? _pendingMessage;
  RemoteMessage? consumePendingMessage() {
    final msg = _pendingMessage;
    _pendingMessage = null;
    return msg;
  }

  // ── Register FCM token with backend ────────────────────────────────────────
  Future<void> registerToken({required Dio dio, String? token}) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint('[FCM] Could not get token');
        return;
      }

      debugPrint('[FCM] Registering token: ${fcmToken.substring(0, 20)}...');

      await dio.post(
        ApiEndpoints.fcmToken,
        data: {
          'token':       fcmToken,
          'device':      'android', // TODO: use Platform.isIOS ? 'ios' : 'android'
          'appVersion':  '1.0.0',
        },
      );

      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  // ── Remove token on logout ─────────────────────────────────────────────────
  Future<void> removeToken({required Dio dio}) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await dio.delete(ApiEndpoints.fcmToken, data: {'token': token});
      await _messaging.deleteToken();
      debugPrint('[FCM] Token removed');
    } catch (e) {
      debugPrint('[FCM] Token removal failed: $e');
    }
  }

  // ── Local notifications setup ──────────────────────────────────────────────
  Future<void> _initLocalNotifications() async {
    // Create Android channel
    final androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    // Init plugin
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // Already requested above
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        // Local notification tapped — payload is the notification type
        debugPrint('[FCM] Local notif tapped: ${details.payload}');
        if (_onNotificationTap != null && details.payload != null) {
          _onNotificationTap!(details.payload!);
        }
      },
    );
  }

  // ── Foreground message → show local notification ───────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C63FF),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'] ?? '',
    );

    // Notify unread count listeners
    _onNewNotification?.call(message);
  }

  // ── Notification tapped (background state) ─────────────────────────────────
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped (background): ${message.data}');
    final type = message.data['type'] ?? '';
    _onNotificationTap?.call(type);
  }

  // ── Callbacks set by the app layer ────────────────────────────────────────
  // Called when a new notification arrives (foreground) — to refresh badge count
  void Function(RemoteMessage)? _onNewNotification;
  void Function(String type)? _onNotificationTap;

  void setOnNewNotification(void Function(RemoteMessage) cb) {
    _onNewNotification = cb;
  }

  void setOnNotificationTap(void Function(String type) cb) {
    _onNotificationTap = cb;
  }
}