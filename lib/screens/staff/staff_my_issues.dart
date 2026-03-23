import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import 'staff_issue_detail.dart';

class StaffMyIssues extends StatefulWidget {
  final int userId;

  const StaffMyIssues({super.key, required this.userId});

  @override
  State<StaffMyIssues> createState() => _StaffMyIssuesState();
}

class _StaffMyIssuesState extends State<StaffMyIssues> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _issuesFuture = _apiService.getMaintenanceIssues(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assigned Tasks'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _issuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading issues: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: AppColors.secondary.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.assignment_turned_in_outlined, size: 60, color: AppColors.secondary),
                   ),
                   const SizedBox(height: 20),
                   const Text('No reports found', style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.w500)),
                   const SizedBox(height: 8),
                   const Text('Issues you report will appear here', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                ],
              ),
            );
          }

          final issues = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffIssueDetailScreen(
                            issue: issue,
                            maintenanceId: widget.userId,
                          ),
                        ),
                      );
                      if (result == true || mounted) {
                        setState(() {
                          _issuesFuture = _apiService.getMaintenanceIssues(widget.userId);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatusChip(issue['status']),
                              Text(
                                '#${issue['id'] ?? 'N/A'}',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            issue['title'] ?? 'Untitled Report',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.category_outlined, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 6),
                              Text(
                                issue['category'] ?? 'General',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  issue['location'] ?? 'Campus',
                                  style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.background),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Priority:', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                              const SizedBox(width: 8),
                              _buildPriorityBadge(issue['priority'] ?? 'Medium'),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: AppColors.secondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor;
    String text = status ?? 'Pending';
    
    switch (status) {
      case 'Resolved': chipColor = AppColors.success; break;
      case 'In Progress': chipColor = AppColors.primary; break;
      case 'Rejected': chipColor = AppColors.error; break;
      default: chipColor = AppColors.warning; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.highlight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

