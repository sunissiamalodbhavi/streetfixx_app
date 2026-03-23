import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../map_picker_screen.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';

class StaffReportIssue extends StatefulWidget {
  final int userId;

  const StaffReportIssue({super.key, required this.userId});

  @override
  State<StaffReportIssue> createState() => _StaffReportIssueState();
}

class _StaffReportIssueState extends State<StaffReportIssue> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  
  double? _latitude;
  double? _longitude;

  String _selectedPriority = 'Medium';
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  String _selectedCategory = 'Garbage';
  final List<String> _categories = ['Garbage', 'Electricity', 'Water', 'Maintenance'];
  
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                const SizedBox(height: 20, width: double.infinity),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10, width: double.infinity),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.photo_library, color: AppColors.textDark, size: 20)),
                  title: const Text('Photo Library', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.photo_camera, color: AppColors.textDark, size: 20)),
                  title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10, width: double.infinity),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Append extra details to description since DB schema is fixed for now
      final fullDescription = """
Priority: $_selectedPriority
Department: ${_departmentController.text}
Description: ${_descriptionController.text}
""";

      await _apiService.reportIssue(
        userId: widget.userId,
        title: _titleController.text,
        description: fullDescription,
        category: _selectedCategory,
        location: _locationController.text,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        imageFile: _imageFile,
        reporterType: 'staff',
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              const Text('Submitted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Issue reported successfully!'),
              const SizedBox(height: 10),
              const Text('Your issue has been reported and will be reviewed shortly.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Issue Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('General Information'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title of the Issue',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) => value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      items: _priorities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedPriority = val!),
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Location Details'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department / Section',
                  prefixIcon: Icon(Icons.maps_home_work_outlined),
                ),
                validator: (value) => value!.isEmpty ? 'Dept is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _latitude = result['latitude'];
                      _longitude = result['longitude'];
                      _locationController.text = result['address'] ?? "Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}";
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Select on Map',
                  prefixIcon: const Icon(Icons.pin_drop_outlined),
                  suffixIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
                  hintText: 'Tap to pick location',
                ),
                validator: (value) => value!.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Detailed Description'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'What is the issue about?',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 32),
              
              _buildSectionHeader('Attachment'),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.softShadow,
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Upload Evidence", 
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "(Optional)", 
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              right: 12,
                              top: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitIssue,
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SUBMIT REPORT'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}


