import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State for switches
  bool _soundAlerts = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    // Custom blue color from the design (approximate)
    const Color headerBlue = Color(0xFFADD8E6); // Light Blue

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
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Placeholder for top right dots
                  Row(
                    children: [
                      _buildDot(),
                      const SizedBox(width: 4),
                      _buildDot(),
                      const SizedBox(width: 4),
                      _buildDot(),
                    ],
                  ),
                ],
              ),
            ),
            
            // 2. White Container with Settings Content
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Notifications Section
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsCard(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Sound alerts',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                    Switch(
                                    value: _soundAlerts,
                                    onChanged: (val) {
                                      setState(() {
                                        _soundAlerts = val;
                                      });
                                    },
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: headerBlue,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Display Section
                            const Text(
                              'Display',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsCard(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Dark mode',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Switch(
                                    value: _darkMode,
                                    onChanged: (val) {
                                      setState(() {
                                        _darkMode = val;
                                      });
                                    },
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: headerBlue,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // About Section
                            const Text(
                              'About',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsCard(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Version',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '1.0.0',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'View',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFFADD8E6), // Light blue
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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

  // Helper for dots in header
  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  // Helper for settings cards (white box with border/shadow)
  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        // Simple border for cleaner look, similar to design
      ),
      child: child,
    );
  }

  // Navigation Logic
  void _navigateToTab(int index) {
    if (index == 0) {
      // Navigate to Schedule Setup
      Navigator.pushReplacementNamed(context, '/setup');
    } else if (index == 1) {
      // Navigate to Reminder List
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      // Already on Settings
      return;
    }
  }

  // Navigation Item Widget
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == 2; // 2 is Settings tab
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