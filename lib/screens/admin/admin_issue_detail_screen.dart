import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../core/api_config.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/full_screen_map_viewer.dart';

class AdminIssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;

  const AdminIssueDetailScreen({super.key, required this.issue});

  @override
  State<AdminIssueDetailScreen> createState() => _AdminIssueDetailScreenState();
}

class _AdminIssueDetailScreenState extends State<AdminIssueDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _issue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
  }

  void _verifyIssue(String status) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.verifyIssue(_issue['id'], status); // Using int ID
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Issue $status')));
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

  void _showAssignDialog() async {
    List<dynamic> staffList = [];
    try {
      staffList = await _apiService.getStaffList();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading staff: $e')));
      return;
    }

    if (!mounted) return;

    int? selectedStaffId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Assign Issue'),
              content: staffList.isEmpty 
                  ? const Text('No maintenance staff available.') 
                  : DropdownButton<int>(
                      value: selectedStaffId,
                      hint: const Text('Select Staff'),
                      isExpanded: true,
                      items: staffList.map<DropdownMenuItem<int>>((staff) {
                        return DropdownMenuItem<int>(
                          value: staff['id'],
                          child: Text('${staff['name']} (${staff['role']} - ${staff['department'] ?? 'N/A'})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        dialogSetState(() => selectedStaffId = val);
                      },
                    ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selectedStaffId == null ? null : () async {
                    try {
                      await _apiService.assignIssue(_issue['id'], selectedStaffId!); // Using int ID
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue assigned successfully')));
                        setState(() {
                           // Optimistically update status
                           _issue['status'] = 'assigned';
                           _issue['assigned_to'] = selectedStaffId;
                           try {
                             var assignedStaff = staffList.firstWhere((s) => s['id'] == selectedStaffId);
                             _issue['assigned_to_name'] = assignedStaff['name'];
                           } catch (e) {
                             // Ignore if not found
                           }
                        });
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentStatus = _issue['status']?.toString().toLowerCase() ?? 'pending';
    bool isAssigned = _issue['assigned_to'] != null || currentStatus == 'assigned';
    bool isCompleted = currentStatus == 'completed';
    bool isResolved = currentStatus == 'resolved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Issue Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor(_issue['status']).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  (_issue['status'] ?? 'Pending').toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(_issue['status']).withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Basic Details
            _buildSectionTitle('Basic Details'),
            _buildDetailRow(Icons.title, 'Title', _issue['title'] ?? 'No Title'),
            _buildDetailRow(Icons.description, 'Description', _issue['description'] ?? 'No Description'),
            _buildDetailRow(Icons.category, 'Category', _issue['category'] ?? 'Uncategorized'),
            _buildDetailRow(Icons.person, 'Reported By', _issue['reported_by'] ?? 'Unknown'),
            _buildDetailRow(Icons.access_time, 'Date', _issue['created_at'] ?? 'Unknown'),
            const SizedBox(height: 20),

            // Location
            _buildSectionTitle('Location'),
            _buildDetailRow(Icons.location_on, 'Address', _issue['location'] ?? 'Unknown Location'),
            if (_issue['latitude'] != null && _issue['longitude'] != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 36.0, top: 4.0, bottom: 12.0),
                child: Text(
                  'Lat: ${_issue['latitude']}, Lng: ${_issue['longitude']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _openGoogleMaps(
                    double.parse(_issue['latitude'].toString()),
                    double.parse(_issue['longitude'].toString()),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          double.parse(_issue['latitude'].toString()),
                          double.parse(_issue['longitude'].toString()),
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('issue-location'),
                          position: LatLng(
                            double.parse(_issue['latitude'].toString()),
                            double.parse(_issue['longitude'].toString()),
                          ),
                        ),
                      },
                      liteModeEnabled: true, // Optimizes for performance in lists/details
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Images
            _buildSectionTitle('Images'),
            Row(
              children: [
                if (_issue['image_url'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reported', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildImage(_issue['image_url']),
                      ],
                    ),
                  ),
                if (_issue['image_url'] != null && _issue['completion_image'] != null)
                  const SizedBox(width: 12),
                if (_issue['completion_image'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildImage(_issue['completion_image']),
                      ],
                    ),
                  ),
              ],
            ),
             if (_issue['image_url'] == null && _issue['completion_image'] == null)
               const Text('No images attached.', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            
            const SizedBox(height: 20),

            // Assignment Info
            if (isAssigned) ...[
              _buildSectionTitle('Assignment Info'),
              _buildDetailRow(Icons.engineering, 'Assigned To', _issue['assigned_to_name'] ?? 'Staff ID: ${_issue['assigned_to']}'),
              // _buildDetailRow(Icons.calendar_today, 'Assigned Date', 'Not tracked'), // If you track assigned_at, add here
              const SizedBox(height: 20),
            ],

            // Completion Info
            if (isCompleted || isResolved) ...[
              const Divider(height: 40),
              _buildSectionTitle('Completion Proof'),
              if (_issue['completion_image'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(_issue['completion_image']),
                    const SizedBox(height: 16),
                  ],
                ),
              if (_issue['completion_note'] != null && _issue['completion_note'].toString().isNotEmpty)
                _buildDetailRow(Icons.note_alt_outlined, 'Maintenance Note', _issue['completion_note']),
              _buildDetailRow(Icons.done_all, 'Completed By', _issue['completed_by_name'] ?? 'Staff ID: ${_issue['completed_by'] ?? "Unknown"}'),
              _buildDetailRow(Icons.schedule, 'Completed At', _issue['completed_at'] ?? 'Unknown'),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isAssigned, isCompleted, isResolved),
    );
  }

  Widget? _buildBottomBar(bool isAssigned, bool isCompleted, bool isResolved) {
    if (isResolved) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
           color: Colors.white,
           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: const Text(
          'Completed',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentMint),
        ),
      );
    }

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _verifyIssue('Reopened'),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _verifyIssue('Resolved'),
                icon: const Icon(Icons.check_rounded),
                label: const Text('VERIFY'),
                style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.accentMint,
                   foregroundColor: AppColors.textPrimary,
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isAssigned) {
      String staffName = _issue['assigned_to_name'] ?? 'Staff ID: ${_issue['assigned_to'] ?? "Unknown"}';
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
           color: Colors.white,
           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Text(
          'Assigned to $staffName',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
         color: Colors.white,
         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: ElevatedButton.icon(
        onPressed: _showAssignDialog,
        icon: const Icon(Icons.assignment_ind_rounded),
        label: const Text('ASSIGN TO STAFF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String urlPath) {
    final fullUrl = urlPath.startsWith('http') ? urlPath : '${ApiConfig.baseUrl}$urlPath';
    return GestureDetector(
      onTap: () {
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
        tag: fullUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            fullUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final s = status?.toLowerCase();
    switch (s) {
      case 'resolved': return AppColors.accentMint;
      case 'completed': return AppColors.accentMint;
      case 'in progress': return AppColors.secondary;
      case 'assigned': return AppColors.secondary;
      case 'rejected': return AppColors.error;
      default: return AppColors.highlightPeach;
    }
  }
}
