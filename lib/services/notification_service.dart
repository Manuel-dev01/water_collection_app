import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart'; // Required for TimeOfDay

import 'package:flutter_timezone/flutter_timezone.dart';

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
    
    // Get the device's local timezone
    try {
      // FIX: Add timeout because this can hang indefinitely offline on some devices
      // We use 'dynamic' to handle version differences in flutter_timezone (String vs TimezoneInfo)
      final dynamic result = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 3));
      
      final String timeZoneName = (result is String) ? result : result.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if something goes wrong to prevent crash
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

  /// ROLE: Requests notification permissions on Android 13+.
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

  /// ROLE: Schedules a single alarm.
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

  /// ROLE: Schedules a weekly recurring notification for a specific day and time.
  /// [day] is 1=Monday, 7=Sunday (standard Dart/ISO).
  Future<void> scheduleWeeklyAlarm(int reminderId, String title, TimeOfDay time, int day) async {
    // 1. Create a "Safe" Native DateTime (using device's real local time)
    final nowNative = DateTime.now();
    
    // 2. Project the user's desired time onto Today's date
    // This creates a DateTime that respects the DEVICE offset (e.g. UTC+1)
    DateTime scheduledNative = DateTime(
      nowNative.year,
      nowNative.month,
      nowNative.day,
      time.hour,
      time.minute,
    );

    // 3. Keep adding days until we hit the target day of the week
    while (scheduledNative.weekday != day || scheduledNative.isBefore(nowNative)) {
       scheduledNative = scheduledNative.add(const Duration(days: 1));
    }

    // 4. Convert the final valid Native time to the Target Timezone (even if it's fell back to UTC)
    // tz.TZDateTime.from() correctly handles the shift:
    // e.g. 14:00 Native (UTC+1) -> 13:00 UTC (if tz.local is UTC)
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

  /// ROLE: Diagnostic test to fire a notification in 5 seconds
  Future<void> testNotification() async {
    debugPrint('Diagnosing: Scheduling TEST notification for 5 seconds from now');
    await _notifications.zonedSchedule(
      99999,
      'Test Notification',
      'If you see this, notifications work!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel_v2', // Use the confirmed channel
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