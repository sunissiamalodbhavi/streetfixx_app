import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../student/student_home.dart';
import '../student/hostel_home.dart';
import '../staff/staff_home.dart';
import '../staff/quarters_home.dart';
import '../admin/admin_home.dart';

import 'student_signup_screen.dart';
import 'hall_student_signup_screen.dart';
import 'staff_signup_screen.dart';
import '../maintenance/campus_maintenance_home.dart';
import 'campus_maintenance_signup_screen.dart';
import '../../core/notification_service.dart';
import '../../core/session_manager.dart';


class LoginScreen extends StatefulWidget {
  final String? initialUserType;

  const LoginScreen({super.key, this.initialUserType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedUserType = 'Campus User';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  final List<String> _userTypes = [
    'Campus User',
    'Staff',
    'Maintenance',
    'Admin',
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialUserType != null && _userTypes.contains(widget.initialUserType)) {
      _selectedUserType = widget.initialUserType!;
    }
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      final role = response['role'];
      final userId = response['user_id'];
      final name = response['name'];

      // ✅ Handle FCM Token
      try {
        final fcmToken = await NotificationService().getToken();
        if (fcmToken != null) {
          await _apiService.saveFcmToken(userId, fcmToken);
          print("✅ FCM Token saved to backend");
        }
      } catch (e) {
        print("⚠️ Failed to save FCM token: $e");
        // Don't block login if FCM fails
      }

      // ✅ Save User Session
      await SessionManager.saveSession(
        role: role.toString(),
        userId: userId,
        userName: name ?? '',
      );

      Widget nextScreen;
      final normalizedRole = role.toString().toLowerCase().trim();

      if (normalizedRole == 'admin') {
        nextScreen = const AdminHome();
      } else if (['hall student', 'hall_student', 'hostel student', 'hostel_student'].contains(normalizedRole)) {
        nextScreen = HostelHome(userId: userId, userName: name);
      } else if (normalizedRole == 'staff') {
        nextScreen = StaffHome(userId: userId, userName: name);
      } else if (['quarters resident', 'quarters_resident'].contains(normalizedRole)) {
        nextScreen = QuartersHome(userId: userId);
      } else if (normalizedRole == 'maintenance') {
        nextScreen = CampusMaintenanceHome(userId: userId, userName: name);
      } else {
        // Default to StudentHome for 'student' or any other role
        nextScreen = StudentHome(userId: userId, userName: name);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSignup() {
    if (_selectedUserType == 'Campus User') {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Student Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.green),
                title: const Text('Student (Day Scholar)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentSignupScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.blue),
                title: const Text('Hall Student'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HallStudentSignupScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (_selectedUserType == 'Staff') {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StaffSignupScreen()),
      );
    } else if (_selectedUserType == 'Maintenance') {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CampusMaintenanceSignupScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup not available for this role directly. Please contact admin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Title
              Image.asset(
                'lib/assets/images/camlogo.jpg',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Campus Care',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome back, please login',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // Login Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedUserType,
                        items: _userTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _selectedUserType = val!),
                        decoration: const InputDecoration(
                          labelText: 'Select Role',
                          prefixIcon: Icon(Icons.person_pin_outlined),
                        ),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.trim().endsWith('@mcc.edu.in')) {
                            return 'Email must end with @mcc.edu.in';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        height: 50,
                        child: CustomButton(
                          text: 'LOGIN',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Signup Link
              TextButton(
                onPressed: _navigateToSignup,
                child: RichText(
                  text: TextSpan(
                    text: 'Don\'t have an account? ',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }
