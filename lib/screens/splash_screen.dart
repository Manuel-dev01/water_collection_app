import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
//import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Future<void> _initializeAndNavigate() async {
    // Start minimum timer (so logo is visible for at least 3 seconds)
    final minDelay = Future.delayed(const Duration(seconds: 3));

    // Start initialization tasks in parallel
    final initTasks = Future.wait([
       NotificationService.instance.init(),
       DatabaseService.instance.database,
    ]);

    // Wait for BOTH the timer and the initialization to finish
    await Future.wait([minDelay, initTasks]);

    // 2. Check if the widget is still in the tree before navigating
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/setup');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _initializeAndNavigate(); // - automatic navigation with initialization
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // onTap: _navigateToHome, // Navigate when screen is tapped
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFB8E6E6),
                Color(0xFF7DD3D3),
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Water droplet with calendar icon
                        CustomPaint(
                          size: const Size(120, 140),
                          painter: WaterDropletPainter(),
                        ),
                        const SizedBox(height: 24),
                        // App name
                        const Text(
                          'AquaCollect',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WaterDropletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5DADE2),
          Color(0xFF2E86C1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw water droplet shape
    final path = Path();
    final centerX = size.width / 2;
    
    path.moveTo(centerX, 0);
    
    // Right curve
    path.cubicTo(
      size.width * 0.85, size.height * 0.25,
      size.width, size.height * 0.5,
      size.width, size.height * 0.7,
    );
    
    // Bottom curve
    path.cubicTo(
      size.width, size.height * 0.9,
      size.width * 0.75, size.height,
      centerX, size.height,
    );
    
    path.cubicTo(
      size.width * 0.25, size.height,
      0, size.height * 0.9,
      0, size.height * 0.7,
    );
    
    // Left curve
    path.cubicTo(
      0, size.height * 0.5,
      size.width * 0.15, size.height * 0.25,
      centerX, 0,
    );
    
    path.close();
    canvas.drawPath(path, paint);

    // Draw calendar icon
    final calendarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final calendarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.58),
        width: size.width * 0.45,
        height: size.height * 0.35,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(calendarRect, calendarPaint);

    // Calendar header (blue bar)
    final headerPaint = Paint()..color = const Color(0xFF2E86C1);
    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        calendarRect.left,
        calendarRect.top,
        calendarRect.width,
        size.height * 0.08,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(headerRect, headerPaint);

    // Calendar grid (simplified)
    final gridPaint = Paint()
      ..color = const Color(0xFF2E86C1)
      ..strokeWidth = 1.5;

    final gridStartY = calendarRect.top + size.height * 0.12;
    final gridSpacing = size.height * 0.055;
    final cellWidth = calendarRect.width / 7;

    // Draw horizontal lines
    for (int i = 0; i < 4; i++) {
      final y = gridStartY + (i * gridSpacing);
      canvas.drawLine(
        Offset(calendarRect.left + 4, y),
        Offset(calendarRect.right - 4, y),
        gridPaint,
      );
    }

    // Draw vertical lines
    for (int i = 1; i < 7; i++) {
      final x = calendarRect.left + (i * cellWidth);
      canvas.drawLine(
        Offset(x, gridStartY),
        Offset(x, calendarRect.bottom - 4),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}