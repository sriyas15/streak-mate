import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'socket_events.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';

class SocketService {
  IO.Socket? _socket;
  Ref? _ref;

  void init(Ref ref) {
    _ref = ref;
  }

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await SecureStorageService.instance.getAccessToken();
    if (token == null) return;

    _socket = IO.io(
        AppConstants.apiSocketUrl, // should be 'http://10.0.2.2:5000' — no trailing slash, no path
        IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(1000)
        .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => debugPrint('[Socket] Connected'));
    _socket!.onDisconnect((_) => debugPrint('[Socket] Disconnected'));
    _socket!.onConnectError((e) => debugPrint('[Socket] Error: $e'));
    _socket!.onReconnect((_) => debugPrint('[Socket] Reconnected'));

    _registerHandlers();
  }

  void _registerHandlers() {
  // Log ALL incoming events to see what's arriving
  _socket!.onAny((event, data) {
    debugPrint('[Socket] Event received: $event — $data');
  });

  // Re-register on every reconnect
  _socket!.onReconnect((_) {
    debugPrint('[Socket] Reconnected — re-registering handlers');
    _registerHandlers();
  });

  _socket!.on(SocketEvents.xpEarned, (data) {
    debugPrint('[Socket] XP earned handler fired: $data');
    _ref?.read(authProvider.notifier).updateXP(
          xpPoints: data['total'] as int,
          level: data['level'] as int,
        );
  });

  _socket!.on(SocketEvents.levelUp, (data) {
    debugPrint('[Socket] Level up handler fired: $data');
    _ref?.read(authProvider.notifier).updateXP(
          xpPoints: data['xpPoints'] as int,
          level: data['newLevel'] as int,
        );
  });

  _socket!.on(SocketEvents.calendarUpdated, (data) {
  debugPrint('[Socket] Calendar updated: $data');
  _ref?.read(calendarProvider.notifier).handleSocketUpdate(data);
});

}

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.init(ref);
  return service;
});