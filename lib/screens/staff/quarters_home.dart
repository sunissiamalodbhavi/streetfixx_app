import 'package:flutter/material.dart';
import 'staff_report_issue.dart';
import 'staff_my_issues.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/dashboard_card.dart';

class QuartersHome extends StatelessWidget {
  final int userId;

  const QuartersHome({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Quarters'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                      color: AppColors.secondary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_work_rounded, size: 32, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quarters',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Management System',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Available Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            DashboardCard(
              title: 'Report Issue',
              subtitle: 'Report quarters-related issues',
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StaffReportIssue(userId: userId)),
                );
              },
            ),
            const SizedBox(height: 20),
            DashboardCard(
              title: 'My Issues',
              subtitle: 'Track status of quarters requests',
              icon: Icons.list_alt_rounded,
              iconColor: AppColors.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StaffMyIssues(userId: userId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
