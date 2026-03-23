import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class CampusMaintenanceSignupScreen extends StatefulWidget {
  const CampusMaintenanceSignupScreen({super.key});

  @override
  State<CampusMaintenanceSignupScreen> createState() => _CampusMaintenanceSignupScreenState();
}

class _CampusMaintenanceSignupScreenState extends State<CampusMaintenanceSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _departmentController = TextEditingController(); // Added department
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.signup(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: 'maintenance',
        phone: _phoneController.text,
        department: _departmentController.text,
        rollNo: '', // Not applicable
        gender: _selectedGender!,
        staffId: _staffIdController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup Successful! Please Login.')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(initialUserType: 'Maintenance')),
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
      appBar: AppBar(title: const Text('Maintenance Signup'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.engineering, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => val!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (@mcc.edu.in)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Email is required';
                  if (!val.endsWith('@mcc.edu.in')) return 'Email must end with @mcc.edu.in';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Phone is required';
                  if (val.length != 10) return 'Phone must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _staffIdController,
                decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                validator: (val) => val!.isEmpty ? 'Staff ID is required' : null,
              ),
               const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people)),
                validator: (v) => (v == null || v.isEmpty) ? 'Gender is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work)),
                validator: (val) => val!.isEmpty ? 'Department is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (val) => val!.isEmpty ? 'Password is required' : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Sign Up',
                onPressed: _handleSignup,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
