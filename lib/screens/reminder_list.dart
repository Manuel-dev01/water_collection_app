import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  // Calendar Format
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dummy Data for Schedules
  final List<Map<String, dynamic>> _schedules = [
    {
      'title': 'Weekly Collection',
      'days': 'Mon, Wed, Fri',
      'time': '09:00',
      'isActive': true,
      'status': 'Active', // Badge text
    },
    {
      'title': 'Weekend Schedule',
      'days': 'Sat, Sun',
      'time': '10:00',
      'isActive': true,
      'status': 'Active', // Badge text
    },
  ];

  // Dummy method to simulate events/dots on the calendar
  List<dynamic> _getEventsForDay(DateTime day) {
    // Just return a dummy event for every 3rd day to mimic the dots pattern
    if (day.day % 3 == 0 || day.day % 4 == 0) {
      return ['Event'];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Custom blue color from the design (approximate)
    const Color headerBlue = Color(0xFFADD8E6); // Light Blue
    const Color activeSwitchColor = Color(0xFFADD8E6);

    return Scaffold(
      backgroundColor: headerBlue, // Background for the top part
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder List',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Placeholder for potentially menu icon or profile
                  Container(), 
                ],
              ),
            ),
            
            // 2. White Container with Calendar and List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Calendar Section
                    _buildCalendar(),

                    // "All Schedules" Title
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Schedules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Schedule List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _schedules[index];
                          return _buildScheduleItem(schedule, activeSwitchColor);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 3. Bottom Navigation Bar
             Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), // Using withValues if available, else withOpacity
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Schedule',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.notifications_outlined,
                      label: 'Reminders',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      index: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the Calendar
  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay, // Adding the event loader
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // Styling matches the design loosely
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold
          ),
        ),
        calendarStyle: const CalendarStyle(
           todayDecoration: BoxDecoration(
             color: Color(0xFFADD8E6), // Highlight color
             shape: BoxShape.circle,
           ),
           selectedDecoration: BoxDecoration(
             color: Colors.blue, // Ensure this constant is valid
             shape: BoxShape.circle,
           ),
           markerDecoration: BoxDecoration(
             color: Color(0xFFADD8E6), // Color for the dots
             shape: BoxShape.circle,
           ),
        ),
      ),
    );
  }

  // Helper method to build each Schedule Item
  Widget _buildScheduleItem(Map<String, dynamic> schedule, Color switchActiveColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Optional: add shadow if needed
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                schedule['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Dark text
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFADD8E6).withValues(alpha: 0.5), // Light blue bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  schedule['status'] ?? 'Active',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Days
          Text(
            schedule['days'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // Reminders Label
          const Text(
            'Reminders:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),

          // Time and Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_none, size: 20, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    schedule['time'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              // Custom Switch
              Switch(
                value: schedule['isActive'],
                onChanged: (val) {
                  setState(() {
                    schedule['isActive'] = val;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFADD8E6), // Light blue
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation Logic
  void _navigateToTab(int index) {
    if (index == 0) {
      // Navigate to Schedule Setup
      Navigator.pushReplacementNamed(context, '/setup');
    } else if (index == 1) {
      // Already on Reminder List
      return;
    } else if (index == 2) {
      // Navigate to Settings
      Navigator.pushReplacementNamed(context, '/settings');
    }
  }

  // Navigation Item Widget
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == 1; // 1 is Reminders tab
    return GestureDetector(
      onTap: () => _navigateToTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF87CEEB) : const Color(0xFF999999),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF87CEEB) : const Color(0xFF999999),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}