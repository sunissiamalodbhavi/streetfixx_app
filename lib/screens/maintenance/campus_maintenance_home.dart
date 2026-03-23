import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../auth/login_screen.dart';
import '../../core/session_manager.dart';
import 'maintenance_issue_detail.dart';

class CampusMaintenanceHome extends StatefulWidget {
  final int userId;
  final String userName;

  const CampusMaintenanceHome({super.key, required this.userId, required this.userName});

  @override
  State<CampusMaintenanceHome> createState() => _CampusMaintenanceHomeState();
}

class _CampusMaintenanceHomeState extends State<CampusMaintenanceHome> {
  final ApiService _apiService = ApiService();

  Future<void> _completeTask(int issueId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    File imageFile = File(photo.path);

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading proof...')));
      
      await _apiService.completeIssue(issueId, widget.userId, imageFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task completed successfully!')));
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Maintenance'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.userName}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your assigned maintenance tasks',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _apiService.getMaintenanceIssues(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final issues = snapshot.data ?? [];
                if (issues.isEmpty) {
                  return const Center(child: Text('No assigned tasks.'));
                }
                return ListView.builder(
                  itemCount: issues.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    final isCompleted = issue['status'] == 'Completed' || issue['status'] == 'Resolved';
                    
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaintenanceIssueDetailScreen(
                              issue: issue,
                              maintenanceId: widget.userId,
                              maintenanceName: widget.userName,
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {});
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      issue['title'] ?? 'No Title',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(issue['status']).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (issue['status'] ?? 'Assigned').toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(issue['status']).withOpacity(0.8), 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondary.withOpacity(0.6)),
                                  const SizedBox(width: 6),
                                  Text('${issue['category']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(width: 20),
                                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary.withOpacity(0.6)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${issue['location']}', 
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                issue['description'] ?? '', 
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Resolved': return AppColors.accentMint;
      case 'Completed': return AppColors.accentMint;
      case 'In Progress': return AppColors.secondary;
      case 'Rejected': return AppColors.error;
      default: return AppColors.highlightPeach;
    }
  }
}
