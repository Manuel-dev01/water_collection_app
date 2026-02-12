import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart'; // Required for TimeOfDay

/// ROLE: High-priority hardware alarms.
/// This handles the actual 'Reminders' by talking to the phone's OS.
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  /// ROLE: Initializes the notification engine and timezone data.
  Future<void> init() async {
    // Required to handle Daylight Savings and local time offsets correctly.
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(const InitializationSettings(android: android));
  }

  /// ROLE: Schedules a single alarm.
  Future<void> scheduleAlarm(int reminderId, String title, DateTime scheduledTime) async {
    await _notifications.zonedSchedule(
      reminderId,
      'Water Collection Reminder',
      'Time to collect for: $title',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// ROLE: Schedules a weekly recurring notification for a specific day and time.
  /// [day] is 1=Monday, 7=Sunday (standard Dart/ISO).
  Future<void> scheduleWeeklyAlarm(int reminderId, String title, TimeOfDay time, int day) async {
    final now = tz.TZDateTime.now(tz.local);
    
    // Calculate the next occurrence of this day/time
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, 
      now.year, 
      now.month, 
      now.day, 
      time.hour, 
      time.minute
    );

    // Initial check: if today is the day but time passed, or if day is different
    while (scheduledDate.weekday != day || scheduledDate.isBefore(now)) {
       // Add 1 day until we hit the correct weekday. 
       // If it's today but passed, loop will run 7 times? No.
       // We can optimize, but loop is safe and simple for finding "Next Day X".
       scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _notifications.zonedSchedule(
      reminderId,
      'Water Collection Reminder',
      'Time to collect: $title',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel_recurring',
          'Weekly Water Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // KEY: Repeats weekly
    );
  }

  /// ROLE: Cancels a specific alarm.
  Future<void> cancelAlarm(int reminderId) async {
    await _notifications.cancel(reminderId);
  }

  /// ROLE: Cancels all alarms associated with a schedule ID.
  /// Strategy: We know the ID generation logic is (scheduleId * 1000) + ...
  /// So we cancel a reasonable range of potential IDs.
  Future<void> cancelAllSchedulesForId(int scheduleId) async {
    // We assume max 50 reminders per schedule * 7 days = 350 IDs. 
    // Range: scheduleId * 1000 to scheduleId * 1000 + 500 (safety margin)
    int startId = scheduleId * 1000;
    int endId = startId + 500;
    
    for (int i = startId; i < endId; i++) {
        await _notifications.cancel(i);
    }
  }
}