import 'package:flutter/material.dart';

class ReminderScheduleModel {
  final String id;
  final String title;
  final List<String> days; // e.g., ["Mon", "Wed", "Fri"]
  final List<TimeOfDay> reminders;
  bool isActive;

  ReminderScheduleModel({
    required this.id,
    required this.title,
    required this.days,
    required this.reminders,
    this.isActive = true,
  });
}
