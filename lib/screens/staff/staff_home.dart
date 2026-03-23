import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../screens/auth/login_screen.dart';
import '../../core/session_manager.dart';
import 'staff_report_issue.dart';
import 'staff_my_issues.dart';
import 'guest_booking.dart';
import 'quarters_home.dart';
import '../../widgets/dashboard_card.dart';

class StaffHome extends StatelessWidget {
  final int userId;
  final String? userName;

  const StaffHome({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
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
                color: AppColors.secondary.withOpacity(0.15),
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
                    child: const Icon(Icons.work_outline_rounded, size: 32, color: AppColors.secondary),
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
                          userName ?? 'Staff Member',
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
              subtitle: 'Report maintenance or other issues',
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffReportIssue(userId: userId),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            DashboardCard(
              title: 'My Issues',
              subtitle: 'Track status of reported issues',
              icon: Icons.list_alt_rounded,
              iconColor: AppColors.secondary,
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => StaffMyIssues(userId: userId),
                   ),
                 );
              },
            ),
            const SizedBox(height: 20),

            DashboardCard(
              title: 'Guest House Booking',
              subtitle: 'Book accommodation for guests',
              icon: Icons.hotel_rounded,
              iconColor: AppColors.accentMint,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuestBooking(userId: userId),
                  ),
                );
              },
            ),
             const SizedBox(height: 20),

            DashboardCard(
              title: 'Staff Quarters',
              subtitle: 'Manage quarters requests',
              icon: Icons.holiday_village_rounded,
              iconColor: AppColors.highlightPeach,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuartersHome(userId: userId),
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
