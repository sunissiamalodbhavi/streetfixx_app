import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';

class GuestBooking extends StatefulWidget {
  final int userId;
  const GuestBooking({super.key, required this.userId});

  @override
  State<GuestBooking> createState() => _GuestBookingState();
}

class _GuestBookingState extends State<GuestBooking> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();
  final _guestsController = TextEditingController();
  
  String _selectedRoomType = 'Non-AC';
  final List<String> _roomTypes = ['Non-AC', 'AC', 'Suite'];

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both From and To dates')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await ApiService().bookGuestHouse(
        userId: widget.userId,
        name: _nameController.text,
        phone: _phoneController.text,
        department: _departmentController.text,
        guests: _guestsController.text,
        roomType: _selectedRoomType,
        fromDate: "${_fromDate!.toLocal()}".split(' ')[0],
        toDate: "${_toDate!.toLocal()}".split(' ')[0],
        reason: _reasonController.text,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary), // Sage Green
              const SizedBox(width: 10),
              const Text('Request Sent'),
            ],
          ),
          content: const Text('Your guest house booking request has been submitted for approval.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                // Navigate back or reset form
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Guest House Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Guest Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter guest name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter contact number';
                  if (value.length < 10) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter department' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _guestsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. of Guests',
                        prefixIcon: Icon(Icons.group_outlined),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRoomType,
                      items: _roomTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedRoomType = val!),
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        prefixIcon: Icon(Icons.bed_outlined),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'From Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _fromDate != null ? "${_fromDate!.toLocal()}".split(' ')[0] : 'Select Date',
                          style: TextStyle(color: _fromDate != null ? AppColors.textPrimary : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'To Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _toDate != null ? "${_toDate!.toLocal()}".split(' ')[0] : 'Select Date',
                          style: TextStyle(color: _toDate != null ? AppColors.textPrimary : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Stay',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? 'Please enter reason' : null,
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'SUBMIT REQUEST',
                onPressed: _submitBooking,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
