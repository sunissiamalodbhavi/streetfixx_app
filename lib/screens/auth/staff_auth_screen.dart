import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'staff_login_screen.dart';
import 'staff_signup_screen.dart';

class StaffAuthScreen extends StatelessWidget {
  const StaffAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Authentication'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.badge, size: 80, color: Colors.teal),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Staff Login',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Staff Signup',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffSignupScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
