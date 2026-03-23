import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/dashboard_card.dart';
import '../auth/login_screen.dart';
import '../../core/session_manager.dart';
import 'report_issue.dart';
import 'my_issues_screen.dart';

class HostelHome extends StatelessWidget {
  final int userId;
  final String userName;

  const HostelHome({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hall Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_rounded, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $userName!',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Hall Student Resident',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            DashboardCard(
              title: 'Report Issues',
              subtitle: 'Report maintenance or facility issues',
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.secondary,
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
              subtitle: 'Track your reported issues',
              icon: Icons.list_alt_rounded,
              iconColor: AppColors.primary,
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
