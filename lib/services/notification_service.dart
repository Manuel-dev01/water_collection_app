import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart'; // Required for TimeOfDay

import 'package:flutter_timezone/flutter_timezone.dart';

/// Service to handle local notifications and scheduling.
/// Manages high-priority hardware alarms using flutter_local_notifications.
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  /// Initializes the notification engine and configures the local timezone.
  Future<void> init() async {
    // Required to handle Daylight Savings and local time offsets correctly.
    tz.initializeTimeZones();
    
    // Get the device's local timezone
    try {
      // We use a timeout because retrieving the timezone can hang indefinitely 
      // on some devices when offline.
      // We use 'dynamic' to handle potential version differences in flutter_timezone.
      final dynamic result = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 3));
      
      final String timeZoneName = (result is String) ? result : result.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone retrieval fails to prevent app crash.
      // This ensures the app can still function, albeit with potentially offset notification times
      // if not handled carefully during scheduling (handled in scheduleWeeklyAlarm).
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('Error setting local timezone (Defaulting to UTC): $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = 
        InitializationSettings(android: android);
    
    await _notifications.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
    debugPrint('NotificationService initialized');
  }

  /// Requests notification permissions for Android 13+.
  Future<bool?> requestNotificationsPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
      return await androidImplementation.requestNotificationsPermission();
    }
    return null;
  }

  /// Schedules a single one-time alarm.
  Future<void> scheduleAlarm(int reminderId, String title, DateTime scheduledTime) async {
    await _notifications.zonedSchedule(
      reminderId,
      'Water Collection Reminder',
      'Time to collect for: $title',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel_v2',
          'Water Reminders V2',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ongoing: true,
          autoCancel: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules a weekly recurring notification for a specific day and time.
  /// [day] is 1=Monday, 7=Sunday (standard Dart/ISO).
  Future<void> scheduleWeeklyAlarm(int reminderId, String title, TimeOfDay time, int day) async {
    // 1. Create a "Safe" Native DateTime using the device's real local time.
    final nowNative = DateTime.now();
    
    // 2. Project the user's desired time onto Today's date.
    DateTime scheduledNative = DateTime(
      nowNative.year,
      nowNative.month,
      nowNative.day,
      time.hour,
      time.minute,
    );

    // 3. Keep adding days until we find the next occurrence of the target weekday.
    while (scheduledNative.weekday != day || scheduledNative.isBefore(nowNative)) {
       scheduledNative = scheduledNative.add(const Duration(days: 1));
    }

    // 4. Convert the final valid Native time to the Target Timezone.
    // tz.TZDateTime.from() handles the conversion correctly even if tz.local is UTC (offline fallback).
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledNative, tz.local);
    
    debugPrint('Scheduling weekly alarm: ID=$reminderId, Title=$title, Native=$scheduledNative, TZ=$scheduledDate');
    
    await _notifications.zonedSchedule(
      reminderId,
      'Water Collection Reminder',
      'Time to collect: $title',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel_recurring_v2',
          'Weekly Water Reminders V2',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeats weekly
    );
  }

  /// Cancels a specific alarm by ID.
  Future<void> cancelAlarm(int reminderId) async {
    await _notifications.cancel(reminderId);
  }

  /// Cancels all alarms associated with a schedule ID.
  /// Scans a reserved range of IDs based on the scheduleId (scheduleId * 1000).
  Future<void> cancelAllSchedulesForId(int scheduleId) async {
    // We assume max 50 reminders per schedule * 7 days.
    // Range: scheduleId * 1000 to scheduleId * 1000 + 500
    int startId = scheduleId * 1000;
    int endId = startId + 500;
    
    for (int i = startId; i < endId; i++) {
        await _notifications.cancel(i);
    }
  }

  /// Diagnostic test to fire a notification in 5 seconds.
  Future<void> testNotification() async {
    debugPrint('Diagnosing: Scheduling TEST notification for 5 seconds from now');
    await _notifications.zonedSchedule(
      99999,
      'Test Notification',
      'If you see this, notifications work!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel_v2',
          'Water Reminders V2',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
     debugPrint('Diagnosing: TEST notification scheduled');
  }
}