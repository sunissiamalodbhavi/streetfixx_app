import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/auth/login_screen.dart';
import 'core/api_config.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'core/session_manager.dart';

// Dashboard imports
import 'screens/student/student_home.dart';
import 'screens/student/hostel_home.dart';
import 'screens/staff/staff_home.dart';
import 'screens/staff/quarters_home.dart';
import 'screens/admin/admin_home.dart';
import 'screens/maintenance/campus_maintenance_home.dart';

/// 🔔 Background message handler (required for FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background message received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  // ✅ Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Foreground listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("🔔 Foreground message received: ${message.notification?.title}");
    notificationService.showNotification(message);
  });

  // ✅ Initialize API config (your existing setup)
  await ApiConfig.init();

  // ✅ Check Login Session
  bool loggedIn = await SessionManager.isLoggedIn();
  Widget initialScreen = const LoginScreen();

  if (loggedIn) {
    String? role = await SessionManager.getRole();
    int? userId = await SessionManager.getUserId() ?? 1;
    String? userName = await SessionManager.getUserName() ?? '';

    if (role != null) {
      final normalizedRole = role.toLowerCase().trim();
      if (normalizedRole == 'admin') {
        initialScreen = const AdminHome();
      } else if (['hall student', 'hall_student', 'hostel student', 'hostel_student'].contains(normalizedRole)) {
        initialScreen = HostelHome(userId: userId, userName: userName);
      } else if (normalizedRole == 'staff') {
        initialScreen = StaffHome(userId: userId, userName: userName);
      } else if (['quarters resident', 'quarters_resident'].contains(normalizedRole)) {
        initialScreen = QuartersHome(userId: userId);
      } else if (normalizedRole == 'maintenance') {
        initialScreen = CampusMaintenanceHome(userId: userId, userName: userName);
      } else {
        // Default to StudentHome
        initialScreen = StudentHome(userId: userId, userName: userName);
      }
    }
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}
