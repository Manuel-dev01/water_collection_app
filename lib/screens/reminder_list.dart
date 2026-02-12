import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/schedule_model.dart';
import '../services/notification_service.dart';

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

  // Real Data
  List<Schedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshSchedules();
  }

  Future<void> _refreshSchedules() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.instance.getAllSchedules();
    if (mounted) {
      setState(() {
        _schedules = data;
        _isLoading = false;
      });
    }
  }

  // Real event loader based on saved schedules
  List<dynamic> _getEventsForDay(DateTime day) {
    // 1 (Mon) -> 7 (Sun)
    final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final String dayName = weekDays[day.weekday - 1];

    // Find active schedules that include this day
    return _schedules.where((s) {
      return s.isActive == 1 && s.selectedDays.contains(dayName);
    }).toList();
  }

  Future<void> _toggleScheduleActive(Schedule schedule, bool newValue) async {
    try {
      await DatabaseService.instance.toggleScheduleActive(schedule.id!, newValue);
      
      // Handle Notifications Logic (Simplified for now - strictly enable/disable)
      // Ideally we'd reschedule properly, but here we trigger a full data refresh
      // which is cleaner for the UI state.
      
      // Update local state optmistically or refresh
      _refreshSchedules();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final backgroundColor = Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFFADD8E6);
    final containerColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor, 
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
                  Text(
                    'Reminder List',
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(), 
                ],
              ),
            ),
            
            // 2. White Container with Calendar and List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Calendar Section
                    _buildCalendar(textColor),

                    // "All Schedules" Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Schedules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),

                    // Schedule List
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _schedules.isEmpty
                            ? Center(child: Text('No schedules yet. Add one!', style: TextStyle(color: textColor)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _schedules.length,
                                itemBuilder: (context, index) {
                                  final schedule = _schedules[index];
                                  return _buildScheduleItem(schedule, backgroundColor, cardColor, textColor);
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
                color: containerColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
  Widget _buildCalendar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay, 
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
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
          rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
        ),
        calendarStyle: CalendarStyle(
           defaultTextStyle: TextStyle(color: textColor),
           weekendTextStyle: TextStyle(color: textColor),
           todayDecoration: const BoxDecoration(
             color: Color(0xFFADD8E6), 
             shape: BoxShape.circle,
           ),
           selectedDecoration: const BoxDecoration(
             color: Colors.blue, 
             shape: BoxShape.circle,
           ),
           markerDecoration: const BoxDecoration(
             color: Color(0xFFADD8E6), 
             shape: BoxShape.circle,
           ),
        ),
      ),
    );
  }

  // Helper method to build each Schedule Item
  Widget _buildScheduleItem(Schedule schedule, Color switchColor, Color cardColor, Color textColor) {
    bool isActive = schedule.isActive == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
             color: Colors.grey.withOpacity(0.1),
             blurRadius: 4,
             offset: const Offset(0, 2),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                schedule.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive 
                      ? const Color(0xFFADD8E6).withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black54) : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Days
          Text(
            schedule.selectedDays,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Reminders Label
          Text(
            'Reminders:',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),

          // Time and Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_none, size: 20, color: textColor.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    schedule.reminderTimes.join(', '), // Show all times
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              
              // Custom Switch
              Switch(
                value: isActive,
                onChanged: (val) {
                  _toggleScheduleActive(schedule, val);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: switchColor, // Light blue or Theme primary
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
    
    // Use theme colors
    final selectedColor = const Color(0xFF87CEEB);
    final unselectedColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF999999);

    return GestureDetector(
      onTap: () => _navigateToTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}