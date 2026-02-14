import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/schedule_model.dart';
import '../services/notification_service.dart';

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  final TextEditingController _scheduleNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _fullDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  final TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  // List to store multiple reminder times
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
  final int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    // Request notification permissions when the screen loads
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await NotificationService.instance.requestNotificationsPermission();
  }

  @override
  void dispose() {
    _scheduleNameController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null && picked != _selectedTimes[index]) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  void _addReminder() {
    setState(() {
      _selectedTimes.add(const TimeOfDay(hour: 9, minute: 0));
    });
  }

  void _removeReminder(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // --- SAVE LOGIC ---
  Future<void> _saveSchedule() async {
    // 1. Validate Input
    final title = _scheduleNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name')),
      );
      return;
    }

    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    // 2. Prepare Data
    // Construct selected days string (e.g., "Mon, Wed, Fri")
    List<String> selectedDayNames = [];
    for (int i = 0; i < 7; i++) {
      if (_selectedDays[i]) {
        selectedDayNames.add(_fullDayNames[i]);
      }
    }
    String selectedDaysStr = selectedDayNames.join(', ');

    // Prepare Reminder Strings for DB
    List<String> reminderTimeStrings = _selectedTimes.map((t) {
      // Store as 24h format HH:mm for simplicity and sorting
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }).toList();

    // 3. Create Schedule Object
    // Note: We use the current date as 'collectionDate' just to have a valid date,
    // though the logic relies on 'selectedDays' for recurrence.
    final newSchedule = Schedule(
      title: title,
      collectionDate: DateTime.now().toIso8601String().split('T')[0],
      selectedDays: selectedDaysStr,
      notes: _notesController.text.trim(),
      isActive: 1,
      reminderTimes: reminderTimeStrings,
    );

    try {
      // 4. Save to Database
      int scheduleId = await DatabaseService.instance.saveFullSchedule(newSchedule);

      // 5. Schedule Notifications
      // Strategy: ID = scheduleId * 1000 + timeIndex * 10 + dayIndex
      // This ensures unique IDs for every alarm of this schedule.
      for (int t = 0; t < _selectedTimes.length; t++) {
        TimeOfDay time = _selectedTimes[t];
        
        for (int d = 0; d < 7; d++) {
          if (_selectedDays[d]) {
            // Day index 0 is Monday (1), 6 is Sunday (7)
            int weekday = d + 1; 

            // Generate a unique ID for each notification.
            // Formula: ScheduleID * 1000 + TimeIndex * 10 + WeekdayIndex
            int notificationId = (scheduleId * 1000) + (t * 10) + weekday;
            
            await NotificationService.instance.scheduleWeeklyAlarm(
              notificationId,
              title,
              time,
              weekday,
            );
          }
        }
      }

      if (mounted) {
        // Show Custom Top Banner
        _showTopBanner(context, 'Schedule saved successfully!');
        
        // Wait for the user to see the banner
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
             Navigator.pushReplacementNamed(context, '/home');
          }
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e')),
        );
      }
    }
  }

  void _navigateToTab(int index) {
    if (index == 0) {
      // Already on Schedule screen
      return;
    } else if (index == 1) {
      // Navigate to Reminders screen
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      // Navigate to Settings screen
      Navigator.pushReplacementNamed(context, '/settings');
    }
  }

  // --- FEEDBACK LOGIC ---
  void _showTopBanner(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50, // Adjust based on safe area
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green, // Success color
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme colors
    final backgroundColor = Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFFADD8E6);
    final containerColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor, // Match ReminderListScreen
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Custom Header (Matching ReminderListScreen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                children: [
                  Text(
                    'Create Schedule', 
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. White Container with Form content
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
                     Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Schedule Name
                              const Text(
                                'Schedule name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey, // Adaptive or use textColor
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _scheduleNameController,
                                decoration: InputDecoration(
                                  hintText: 'e.g., Daily Collection',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[800] 
                                      : const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Select Days
                              Text(
                                'Select days',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(7, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDays[index] = !_selectedDays[index];
                                      });
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _selectedDays[index]
                                            ? const Color(0xFF87CEEB)
                                            : const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _dayLabels[index],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedDays[index]
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Reminders Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reminders',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addReminder,
                                    icon: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Color(0xFF87CEEB),
                                    ),
                                    label: const Text(
                                      'Add reminder',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF87CEEB),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Time Pickers List
                              ..._selectedTimes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final time = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _selectTime(context, index),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.grey[800] 
                                                  : const Color(0xFFF5F5F5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: Colors.grey[600],
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _formatTime(time),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: Colors.grey[600],
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_selectedTimes.length > 1) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.grey),
                                          onPressed: () => _removeReminder(index),
                                          tooltip: 'Remove reminder',
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                              
                              const SizedBox(height: 32),
                              
                              // Add Notes
                              Text(
                                'Add notes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Enter any additional notes...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveSchedule, // Call the new save method
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF87CEEB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save schedule',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 40), // Bottom padding
                            ],
                          ),
                        ),
                     ),
          
                    // Bottom Navigation
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentTab == index;
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