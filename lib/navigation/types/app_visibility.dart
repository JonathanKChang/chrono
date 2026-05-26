import 'package:flutter_fgbg/flutter_fgbg.dart';

import 'package:clock_app/alarm/types/ringing_manager.dart';
import 'package:clock_app/app.dart';
import 'package:clock_app/notifications/types/alarm_notification_arguments.dart';
import 'package:clock_app/navigation/types/routes.dart';
import 'package:flutter/material.dart';

class AppVisibility {
  static AppLifecycleListener? _lifecycleListener;

  static FGBGType _state = FGBGType.foreground;

  static FGBGType get state => _state;

  static void setState(FGBGType type) {
    _state = type;
  }

  static void initialize() {
    // if (loadTextFileSync(fullscreenIntentKey) == "true") {
    //   saveTextFile(fullscreenIntentKey, "false");
    // } else {
      // setState(FGBGType.foreground);
    // }

    _lifecycleListener = AppLifecycleListener(
      onResume: _handleForeground,
    );
  }

  static void dispose() {
    _lifecycleListener?.dispose();
  }

  static bool _foregroundHandled = false;

  static void _handleForeground() async {
    // Skip if we already handled this foreground transition.
    if (_foregroundHandled) return;
    _foregroundHandled = true;

    final navigator = App.navigatorKey.currentState;
    if (navigator == null) return;

    // Skip if already on a notification screen.
    final currentRoute = Routes.currentRoute;
    if (currentRoute == Routes.alarmNotificationRoute ||
        currentRoute == Routes.timerNotificationRoute) {
      return;
    }

    if (RingingManager.isAlarmRinging) {
      navigator.pushNamed(
        Routes.alarmNotificationRoute,
        arguments: AlarmNotificationArguments(
          scheduleIds: [RingingManager.ringingAlarmId],
          tasksOnly: false,
          dismissType: AlarmDismissType.dismiss,
        ),
      );
    } else if (RingingManager.isTimerRinging) {
      navigator.pushNamed(
        Routes.timerNotificationRoute,
        arguments: AlarmNotificationArguments(
          scheduleIds: RingingManager.ringingTimerIds,
          tasksOnly: false,
          dismissType: AlarmDismissType.dismiss,
        ),
      );
    }
  }

  static void resetForegroundHandled() {
    _foregroundHandled = false;
  }
}
