import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    tz.initializeTimeZones();
  }

  static Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      0,
      'Daily Diary Reminder ✍️',
      'Don’t forget to spill your vibes today!',
      _nextInstanceOfHour(21),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diary_channel',
          'Diary Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder() async {
    await _notifications.cancel(0);
  }

  static tz.TZDateTime _nextInstanceOfHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    return scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;
  }
}
