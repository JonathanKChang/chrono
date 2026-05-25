# TODO

## Goal
Add an "Infinite Repeat" option to timers that, when enabled, resets and restarts the timer
 automatically whenever it finishes. When multiple timers finish together (rare edge case),
Stop/Restart applies to all of them as a group — same as current dismiss behavior.

## Tasks

### 1. Add "Infinite Repeat" setting schema
- [ ] Add `SwitchSetting("Infinite Repeat", ...)` to `timerSettingsSchema` in
  `lib/timer/data/timer_settings_schema.dart`, placed alongside the existing "Delete After
  Finishing" switch for consistency

### 2. Update ClockTimer model
- [ ] Add `_shouldRepeat` (bool) field and `shouldRepeat` getter to `ClockTimer` in
  `lib/timer/types/timer.dart`
- [ ] Set initial value to `false` in both constructors (`ClockTimer()` and `ClockTimer.from()`)
- [ ] Include `'shouldRepeat': _shouldRepeat` in `toJson()`
- [ ] Load `json['shouldRepeat'] ?? false` in `fromJson()`
- [ ] Copy `_shouldRepeat` in `copyFrom()`

### 3. Modify stop behavior for infinite repeat timers
- [ ] In `stopTimer()` in `lib/alarm/logic/alarm_isolate.dart`, before the existing dismiss
  block that handles `shouldDeleteAfterFinishing`, add a check: if `timer.shouldRepeat` is
  true, call `updateTimerById(scheduleId, (timer) => timer.snooze())` to reset and restart
  it, then return early — skip the delete/close logic

### 4. Add visual loop indicator on timer card
- [ ] In `lib/timer/widgets/timer_card.dart`, add a small circular repeat icon
  (`Icons.repeat_rounded`) next to the existing delete-after-finishing trash icon, shown when
  `timer.shouldRepeat` is true — match the same size/color treatment as the trash icon

### 5. Swap "Stop" to "Restart" label on timer notification when infinite repeat is enabled
- [ ] In `lib/timer/screens/timer_notification_screen.dart`, check if any ringing timer has
  `shouldRepeat` set; if so, use "Restart" instead of "Stop" as the dismiss action label
  (override the Dismiss Action Type builder string)
- [ ] In `lib/timer/screens/timer_fullscreen.dart`, update accessibility semantics / tooltip
  on the replay button to say "Restart" when `timer.shouldRepeat` is true (already uses
  `Icons.replay_rounded`, just update the semantic label)

## Notes
- Behavior: When infinite repeat is enabled and the timer finishes, both "Stop" and "Snooze"
  on the notification screen reset the timer to its full original duration and restart it
  automatically. Keeps looping until the user dismisses/stops.
- When multiple timers finish together, they appear on a single screen — Stop/Restart applies
  to all of them as a group (same as current dismiss-all behavior).
- This follows the same pattern as "Delete After Finishing": a per-timer switch stored in
  settings, visible as a small icon on the card.
- The `snooze()` method already handles resetting duration and calling `start()`, which is
  exactly what we need for repeat.
