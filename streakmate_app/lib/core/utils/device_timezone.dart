import 'package:flutter_timezone/flutter_timezone.dart';

class DeviceTimezone {
  static Future<String> getTimezone() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    return timezone.identifier;
  }
}