import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../core/session_manager.dart';
import '../../core/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import 'staff_report_issue.dart';
import 'staff_my_issues.dart';
import 'guest_booking.dart';

class StaffDashboard extends StatelessWidget {
  final String userName;

  const StaffDashboard({super.key, this.userName = 'Sunissi'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 20, color: AppColors.textLight),
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Greeting Section
            Text(
              'Hello, $userName 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Campus Maintenance Overview',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // 📊 Overview Summary Cards (Horizontal Scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildSummaryCard(
                    context,
                    title: 'Total',
                    value: '12',
                    icon: Icons.assignment_outlined,
                    color: AppColors.primary,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Assigned',
                    value: '05',
                    icon: Icons.pending_actions,
                    color: AppColors.secondary,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Completed',
                    value: '04',
                    icon: Icons.check_circle_outline,
                    color: AppColors.accent,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Pending',
                    value: '03',
                    icon: Icons.error_outline,
                    color: AppColors.highlight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 📋 Main Actions Section
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),

            DashboardCard(
              title: 'Report Issue',
              subtitle: 'Report campus maintenance issues instantly',
              icon: Icons.report_problem_outlined,
              iconColor: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffReportIssue(userId: 1)), // Placeholder ID
              ),
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Guest House Booking',
              subtitle: 'Book and manage guest house rooms',
              icon: Icons.hotel_outlined,
              iconColor: AppColors.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuestBooking(userId: 1)),
              ),
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'My Requests',
              subtitle: 'Track status of your submitted requests',
              icon: Icons.history_outlined,
              iconColor: AppColors.accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffMyIssues(userId: 1)), // Placeholder ID
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

