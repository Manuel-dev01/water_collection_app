import 'package:flutter/material.dart';

class ScheduleSetupScreen extends StatelessWidget {
  const ScheduleSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Schedule')),
      body: const Center(child: Text('Setup Screen works!')),
    );
  }
}