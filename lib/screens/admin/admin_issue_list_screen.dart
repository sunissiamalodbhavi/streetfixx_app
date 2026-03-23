import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../widgets/issue_card.dart';
import 'admin_issue_detail_screen.dart';

class AdminIssueListScreen extends StatefulWidget {
  final String role;
  final String title;

  const AdminIssueListScreen({
    super.key,
    required this.role,
    required this.title,
  });

  @override
  State<AdminIssueListScreen> createState() => _AdminIssueListScreenState();
}

class _AdminIssueListScreenState extends State<AdminIssueListScreen> {
  final ApiService _apiService = ApiService();

  Widget _buildIssueList(String status) {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.getAdminIssues(role: widget.role, status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<dynamic> issues = snapshot.data ?? [];
        
        // Safety Fallback: Ensure issues match the requested status
        issues = issues.where((i) {
          final s = i['status']?.toString().toLowerCase() ?? '';
          final requestedStatus = status.toLowerCase();
          if (requestedStatus == 'pending') {
            return s == 'pending';
          } else if (requestedStatus == 'assigned') {
            return s == 'assigned' || s == 'in progress';
          } else if (requestedStatus == 'resolved') {
            return s == 'resolved' || s == 'completed';
          }
          return s == requestedStatus;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: issues.isEmpty
              ? Center(
                  child: Text(
                    'No ${status.toLowerCase()} ${widget.role.replaceAll('_', ' ')} issues found.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    return IssueCard(
                      issue: issue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminIssueDetailScreen(issue: issue),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Assigned"),
              Tab(text: "Resolved"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildIssueList('pending'),
            _buildIssueList('assigned'),
            _buildIssueList('resolved'),
          ],
        ),
      ),
    );
  }
}
