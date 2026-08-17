import 'package:flutter/services.dart';

/// Utility class for keeping the screen on via Android's FLAG_KEEP_SCREEN_ON.
class Wakelock {
  static const platform = MethodChannel('com.vicolo.chrono/wakelock');

  /// Keep the screen on.
  static Future<void> enable() async {
    await platform.invokeMethod('turnOn');
  }

  /// Allow the screen to turn off automatically.
  static Future<void> disable() async {
    await platform.invokeMethod('turnOff');
  }
}
