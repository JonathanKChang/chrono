import 'package:clock_app/common/types/notification_type.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/developer/logic/logger.dart';
import 'package:clock_app/navigation/types/routes.dart';
import 'package:clock_app/notifications/logic/alarm_notifications.dart';
import 'package:clock_app/notifications/types/alarm_notification_arguments.dart';
import 'package:clock_app/notifications/widgets/notification_actions/slide_notification_action.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/timer/types/time_duration.dart';
import 'package:clock_app/timer/types/timer.dart';
import 'package:clock_app/timer/utils/timer_id.dart';
import 'package:clock_app/timer/widgets/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimerNotificationScreen extends StatefulWidget {
  const TimerNotificationScreen({
    super.key,
    required this.scheduleIds,
  });

  final List<int> scheduleIds;

  @override
  State<TimerNotificationScreen> createState() =>
      _TimerNotificationScreenState();
}

class _TimerNotificationScreenState extends State<TimerNotificationScreen> {
  bool get _anyHasRepeat => widget.scheduleIds
      .map(getTimerById)
      .any((t) => t?.shouldRepeat == true);

  String get _stopLabel =>
      "${_anyHasRepeat ? "Restart" : "Stop"} ${widget.scheduleIds.length > 1 ? "All" : ""}";

  late Widget actionWidget = appSettings
      .getGroup("Timer")
      .getSetting("Dismiss Action Type")
      .value
      .builder(
        _stop,
        _addTime,
        _stopLabel,
        '+${getTimerById(widget.scheduleIds.last)?.addLength.floor()}:00',
      );

  void _addTime() {
    dismissAlarmNotification(widget.scheduleIds[0],
        AlarmDismissType.snooze, ScheduledNotificationType.timer);
  }

  void _stop() {
    dismissAlarmNotification(widget.scheduleIds[0],
        AlarmDismissType.dismiss, ScheduledNotificationType.timer);
  }

  void _customSnooze() async {
    final timer = getTimerById(widget.scheduleIds.first);
    if (timer == null) return;
    final duration = await showDurationPicker(context);
    if (duration != null) {
      // Pass snoozeSeconds (total seconds, no rounding loss for sub-minute values).
      dismissAlarmNotification(widget.scheduleIds[0],
          AlarmDismissType.snooze, ScheduledNotificationType.timer,
          snoozeSeconds: duration.inSeconds);
    }
  }

  @override
  void initState() {
    try {
      actionWidget = appSettings
          .getGroup("Timer")
          .getSetting("Dismiss Action Type")
          .value
          .builder(
            _stop,
            _addTime,
            _stopLabel,
            '+${getTimerById(widget.scheduleIds.last)?.addLength.floor()}:00',
          );
    } catch (e) {
      actionWidget = SlideNotificationAction(
        onDismiss: _stop,
        onSnooze: _addTime,
        dismissLabel: _stopLabel,
        snoozeLabel:
            '+${getTimerById(widget.scheduleIds.last)?.addLength.floor()}:00',
      );

      logger.e(e.toString());
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Routes.pop(onlyUpdateRoute: true);
        return true;
      },
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 32, bottom: 16, left: 20, right: 20),
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.scheduleIds.length == 1
                        ? Text(
                            getTimerById(widget.scheduleIds.first)?.label ??
                                "Uknown Timer",
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )
                        : ListView(
                            children: [
                              for (int id in widget.scheduleIds)
                                TimerNotificationCard(
                                    timer: getTimerById(id) ??
                                        ClockTimer(TimeDuration.zero))
                            ],
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    actionWidget,
                    if (appSettings
                        .getGroup("General")
                        .getGroup("Interactions")
                        .getSetting("Enable Custom Snooze")
                        .value)
                      TextButton(
                        onPressed: _customSnooze,
                        child: Text(
                          AppLocalizations.of(context)!.customSnoozeButton,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimerNotificationCard extends StatelessWidget {
  const TimerNotificationCard({
    super.key,
    required this.timer,
  });

  final ClockTimer timer;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              timer.label,
              style: Theme.of(context).textTheme.displayMedium,
            )));
  }
}

class NotificationUtils {}
