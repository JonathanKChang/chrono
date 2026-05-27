import 'dart:async';

import 'package:clock_app/app.dart';
import 'package:clock_app/common/types/notification_type.dart';
import 'package:clock_app/notifications/types/alarm_notification_arguments.dart';
import 'package:clock_app/navigation/types/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';

/// Stores the schedule IDs of currently active alarm/timer notifications.
/// Populated by notification callbacks running in the main isolate.
class _RingingState {
  static List<int> alarmScheduleIds = [];
  static List<int> timerScheduleIds = [];
}

StreamSubscription<FGBGType>? _fgbgSubscription;
Timer? _foregroundDebounce;

/// Called from notification callbacks when an alarm/timer notification is created.
/// Stores schedule IDs so foreground detection code can find them later.
void setRingingNotification(ScheduledNotificationType type, List<int> ids) {
  if (type == ScheduledNotificationType.alarm) {
    _RingingState.alarmScheduleIds = ids;
  } else {
    _RingingState.timerScheduleIds = ids;
  }

  // Push the notification screen regardless of foreground state — this is safe:
  // if the app is backgrounded, App.navigatorKey.currentState will be null.
  // if already on a notification screen, _pushScreen returns early.
  checkAndShowNotificationScreen();
}

/// Clear ringing state when notification is dismissed.
void clearRingingNotification(ScheduledNotificationType type) {
  if (type == ScheduledNotificationType.alarm) {
    _RingingState.alarmScheduleIds = [];
  } else {
    _RingingState.timerScheduleIds = [];
  }
}

/// Initialize foreground detection. Called once from main() after runApp().
Future<void> initializeAppVisibility() async {
  // if (loadTextFileSync(fullscreenIntentKey) == "true") {
  //   saveTextFile(fullscreenIntentKey, "false");
  // } else {
  //   setState(FGBGType.foreground);
  // }

  _fgbgSubscription = FGBGEvents.stream.listen((event) {
    if (event == FGBGType.foreground) {
      // Debounce foreground events to avoid duplicate pushes when the app
      // is launched from a notification.
      _foregroundDebounce?.cancel();
      _foregroundDebounce = Timer(const Duration(milliseconds: 500), () {
        checkAndShowNotificationScreen();
      });
    }
  });
}

/// Clean up resources. Called when the app shuts down.
Future<void> disposeAppVisibility() async {
  _fgbgSubscription?.cancel();
  _foregroundDebounce?.cancel();
}

/// Check if an alarm or timer notification is active and push its screen.
/// Called from FGBG foreground events (main.dart) and as a post-frame fallback
/// from NavScaffold for cold starts.
Future<void> checkAndShowNotificationScreen() async {
  final navigator = App.navigatorKey.currentState;
  if (navigator == null) return;

  // Check alarm notification state.
  if (_RingingState.alarmScheduleIds.isNotEmpty) {
    _pushScreen(
      navigator,
      ScheduledNotificationType.alarm,
      List<int>.from(_RingingState.alarmScheduleIds),
    );
    return;
  }

  // Check timer notification state.
  if (_RingingState.timerScheduleIds.isNotEmpty) {
    _pushScreen(
      navigator,
      ScheduledNotificationType.timer,
      List<int>.from(_RingingState.timerScheduleIds),
    );
  }
}

Future<void> _pushScreen(
  NavigatorState navigator,
  ScheduledNotificationType type,
  List<int> scheduleIds,
) async {
  // Skip if already on this notification screen.
  if (Routes.currentRoute ==
      (type == ScheduledNotificationType.alarm
          ? Routes.alarmNotificationRoute
          : Routes.timerNotificationRoute)) {
    return;
  }

  navigator.pushNamed(
    type == ScheduledNotificationType.alarm
        ? Routes.alarmNotificationRoute
        : Routes.timerNotificationRoute,
    arguments: AlarmNotificationArguments(
      scheduleIds: scheduleIds,
      tasksOnly: false,
      dismissType: AlarmDismissType.dismiss,
    ),
  );
}
