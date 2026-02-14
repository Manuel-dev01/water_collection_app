import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/schedule_setup.dart';
import 'screens/reminder_list.dart';
import 'screens/settings_screen.dart';

void main() {
  // Required for native hardware communication (Notifications/DB)
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}


// Global state for Dark Mode (Simple State Management)
final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Water Collection App',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          // Define Light Theme
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFADD8E6), // Light Blue
              foregroundColor: Colors.white,
            ),
          ),
          // Define Dark Theme
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212), // Dark Background
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F), // Darker Header
              foregroundColor: Colors.white,
            ),
          ),
          // Define the "Map" of your app here
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(), 
            '/home': (context) => const ReminderListScreen(), 
            '/setup': (context) => const ScheduleSetupScreen(),
            '/settings': (context) => const SettingsScreen(), 
          },
        );
      },
    );
  }
}
