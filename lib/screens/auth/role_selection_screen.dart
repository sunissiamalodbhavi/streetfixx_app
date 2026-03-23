import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import 'campus_user_type_screen.dart';
import 'staff_login_screen.dart';
import 'login_screen.dart';
import 'admin_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Access Portal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, size: 80, color: AppColors.secondary),
            ),
            const SizedBox(height: 48),
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select your role to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Campus User',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampusUserTypeScreen()),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Staff',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Campus Maintenance',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen(initialUserType: 'Campus Maintenance')),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Admin',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
