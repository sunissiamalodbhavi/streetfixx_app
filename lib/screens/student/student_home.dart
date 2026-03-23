import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import 'report_issue.dart';
import '../../core/session_manager.dart';
import 'my_issues_screen.dart';
import '../../widgets/dashboard_card.dart';

class StudentHome extends StatelessWidget {
  final int userId;
  final String userName;

  const StudentHome({super.key, this.userId = 1, this.userName = 'Student'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionManager.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Icon(Icons.person, size: 32, color: AppColors.primary),
                   ),
                   const SizedBox(width: 20),
                   Expanded(
                     child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            DashboardCard(
              title: 'Report Issue',
              subtitle: 'Found a problem? Report it here.',
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportIssueScreen(userId: userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            DashboardCard(
              title: 'My Issues',
              subtitle: 'Track status of your reports',
              icon: Icons.list_alt_rounded,
              iconColor: AppColors.secondary,
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => MyIssuesScreen(userId: userId),
                   ),
                 );
              },
            ),
          ],
        ),
      ),
    );
  }
}
