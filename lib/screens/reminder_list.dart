import 'package:flutter/material.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reminders')),
      body: const Center(child: Text('Reminder List works!')),
    );
  }
}