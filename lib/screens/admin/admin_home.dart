import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

import '../../widgets/issue_card.dart';
import '../auth/login_screen.dart';
import '../../core/session_manager.dart';
import 'admin_issue_list_screen.dart';
import 'admin_analytics_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateBookingStatus(int bookingId, String status) async {
    try {
      await _apiService.updateBookingStatus(bookingId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $status')));
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildCategoryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Issues', icon: Icon(Icons.report_problem_outlined)),
            Tab(text: 'Bookings', icon: Icon(Icons.book_online_outlined)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Issues Tab - Category Cards
          FutureBuilder<Map<String, dynamic>>(
            future: _apiService.getAdminIssueCounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final counts = snapshot.data ?? {};
              final studentCount = counts['student_count']?.toString() ?? '0';
              final hallStudentCount = counts['hall_student_count']?.toString() ?? '0';
              final staffCount = counts['staff_count']?.toString() ?? '0';
              
              return RefreshIndicator(
                onRefresh: () async { setState((){}); },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24, top: 8),
                      child: Text(
                        'Issue Categories',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      title: 'Student Issues',
                      count: studentCount,
                      icon: Icons.school_outlined,
                      color: const Color(0xFF64B5F6), // Pastel Blue
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminIssueListScreen(
                              role: 'student',
                              title: 'Student Issues',
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    _buildCategoryCard(
                      title: 'Hall Student Issues',
                      count: hallStudentCount,
                      icon: Icons.domain_outlined,
                      color: const Color(0xFF81C784), // Pastel Green
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminIssueListScreen(
                              role: 'hall_student',
                              title: 'Hall Student Issues',
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    _buildCategoryCard(
                      title: 'Staff Issues',
                      count: staffCount,
                      icon: Icons.work_outline,
                      color: const Color(0xFFFFB74D), // Pastel Orange
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminIssueListScreen(
                              role: 'staff',
                              title: 'Staff Issues',
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Bookings Tab
          FutureBuilder<List<dynamic>>(
            future: _apiService.getAdminBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final bookings = snapshot.data ?? [];
              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings found'));
              }
              return ListView.builder(
                itemCount: bookings.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final status = booking['status'] ?? 'Pending';
                  Color statusColor = Theme.of(context).primaryColor;
                  if (status == 'Approved') statusColor = const Color(0xFFA5D6A7); // Pastel Green
                  if (status == 'Rejected') statusColor = const Color(0xFFEF9A9A); // Pastel Red
                  if (status == 'Pending') statusColor = const Color(0xFFFFE082); // Pastel Amber

                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.book_online, color: Theme.of(context).colorScheme.secondary),
                          title: Text('${booking['resource_type']} - ${booking['purpose']}'),
                          subtitle: Text('By: ${booking['user_name'] ?? 'Unknown'}\nTime: ${booking['start_time']} - ${booking['end_time']}'),
                          isThreeLine: true,
                          trailing: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                        if (status == 'Pending')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _updateBookingStatus(booking['id'], 'Rejected'),
                                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF9A9A)),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _updateBookingStatus(booking['id'], 'Approved'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA5D6A7), foregroundColor: Colors.white),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          
          // Analytics Tab
          const AdminAnalyticsScreen(),
        ],
      ),
    );
  }
}
