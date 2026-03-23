import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../core/api_config.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/full_screen_map_viewer.dart';
import 'submit_completion_screen.dart';

class StaffIssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  final int maintenanceId;

  const StaffIssueDetailScreen({
    super.key,
    required this.issue,
    required this.maintenanceId,
  });

  @override
  State<StaffIssueDetailScreen> createState() => _StaffIssueDetailScreenState();
}

class _StaffIssueDetailScreenState extends State<StaffIssueDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _issue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
  }

  void _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateIssueStatus(_issue['id'], status, widget.maintenanceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
        setState(() {
          _issue['status'] = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    }
  }

  void _showCompleteDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitCompletionScreen(
          issue: _issue,
          maintenanceId: widget.maintenanceId,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _issue['status'] = 'COMPLETED';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canUpdate = _issue['status'] == 'Assigned' || _issue['status'] == 'Reopened';
    bool canComplete = _issue['status'] == 'In Progress' || _issue['status'] == 'Assigned' || _issue['status'] == 'Reopened';
    bool isCompleted = _issue['status'] == 'Completed' || _issue['status'] == 'Resolved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ISSUE #${_issue['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                        _buildPriorityBadge(_issue['priority'] ?? 'Medium'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_issue['title'] ?? 'No Title', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(_issue['category'] ?? 'General', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Section
             _buildSectionTitle('Status'),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: _getStatusColor(_issue['status']).withOpacity(0.1),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Text(
                 (_issue['status'] ?? 'Pending').toUpperCase(),
                 style: TextStyle(color: _getStatusColor(_issue['status']), fontWeight: FontWeight.bold, letterSpacing: 1),
                 textAlign: TextAlign.center,
               ),
             ),
            const SizedBox(height: 20),

            // Description
            _buildSectionTitle('Full Description'),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _issue['description'] ?? 'No description provided.',
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reporter Info
            _buildSectionTitle('Reporting Info'),
            _buildInfoRow(Icons.person_outline, 'Reported By', _issue['reported_by'] ?? 'Unknown'),
            _buildInfoRow(Icons.business_outlined, 'Department', _issue['reporter_department'] ?? 'N/A'),
            _buildInfoRow(Icons.calendar_today_outlined, 'Date', _issue['created_at'] ?? 'N/A'),
            const SizedBox(height: 20),

            // Location Section
            _buildSectionTitle('Location'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(_issue['location'] ?? 'Unknown location', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            if (_issue['latitude'] != null && _issue['longitude'] != null)
              GestureDetector(
                onTap: () {
                  _openGoogleMaps(
                    double.parse(_issue['latitude'].toString()),
                    double.parse(_issue['longitude'].toString()),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
                    child: AbsorbPointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            double.parse(_issue['latitude'].toString()),
                            double.parse(_issue['longitude'].toString()),
                          ),
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('issueLocation'),
                            position: LatLng(
                              double.parse(_issue['latitude'].toString()),
                              double.parse(_issue['longitude'].toString()),
                            ),
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Image Proof
            if (_issue['image_url'] != null) ...[
              _buildSectionTitle('Evidence Photo'),
              GestureDetector(
                onTap: () {
                  final fullUrl = '${ApiConfig.baseUrl}${_issue['image_url']}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        imageUrl: fullUrl,
                        heroTag: fullUrl,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: '${ApiConfig.baseUrl}${_issue['image_url']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      '${ApiConfig.baseUrl}${_issue['image_url']}',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 80), // Space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: isCompleted ? null : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            if (_issue['status'] != 'In Progress')
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _updateStatus('In Progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    foregroundColor: AppColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('START WORK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            if (_issue['status'] != 'In Progress') const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showCompleteDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentMint,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('MARK COMPLETE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high': color = AppColors.error; break;
      case 'medium': color = AppColors.secondary; break;
      default: color = AppColors.accentMint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Resolved': return AppColors.accentMint;
      case 'Completed': return AppColors.accentMint;
      case 'In Progress': return AppColors.secondary;
      case 'Rejected': return AppColors.error;
      case 'Reopened': return AppColors.error;
      default: return AppColors.highlightPeach;
    }
  }
}
