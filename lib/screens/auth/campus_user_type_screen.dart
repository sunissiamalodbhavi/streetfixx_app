import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';

class CampusUserTypeScreen extends StatelessWidget {
  const CampusUserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register As'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_outlined, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Student',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen(initialUserType: 'Student')),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Hall Student',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen(initialUserType: 'Hall Student')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
