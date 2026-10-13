import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../models/life.dart';

class LifeNotify {
  LifeNotify._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static var enabled = false;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    _useDeviceOffset();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    enabled = true;
  }

  static void _useDeviceOffset() {
    final offset = DateTime.now().timeZoneOffset;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
        tz.setLocalLocation(location);
        return;
      }
    }
  }

  static Future<void> sync(List<Habit> habits) async {
    if (!enabled) return;
    await _plugin.cancelAll();
    final now = DateTime.now();
    var id = 1;
    for (final habit in habits) {
      if (habit.remindMinutes <= 0) continue;
      final hour = habit.remindMinutes ~/ 60;
      final minute = habit.remindMinutes % 60;
      for (var i = 0; i < 7; i++) {
        final day = dateOnly(now).add(Duration(days: i));
        final when = DateTime(day.year, day.month, day.day, hour, minute);
        if (!when.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id++,
          habit.name,
          habit.rule,
          tz.TZDateTime.local(when.year, when.month, when.day, when.hour, when.minute),
          const NotificationDetails(
            android: AndroidNotificationDetails('habits', 'Habit reminders', channelDescription: 'A nudge for a habit'),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        if (id > 40) return;
      }
    }
  }

  static Future<void> scheduleFocus(DateTime when) async {
    if (!enabled) return;
    await _plugin.cancel(900);
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      900,
      'Focus block finished',
      'Your Aura Day focus timer is done.',
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('focus', 'Focus timer', channelDescription: 'The end of a focus block'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelFocus() async {
    if (!enabled) return;
    await _plugin.cancel(900);
  }
}
