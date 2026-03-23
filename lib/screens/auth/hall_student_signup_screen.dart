import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';

class HallStudentSignupScreen extends StatefulWidget {
  const HallStudentSignupScreen({super.key});

  @override
  State<HallStudentSignupScreen> createState() => _HallStudentSignupScreenState();
}

class _HallStudentSignupScreenState extends State<HallStudentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hallNameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _apiService.signup(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: 'hall_student',
          phone: _phoneController.text,
          department: _departmentController.text,
          rollNo: _rollNoController.text,
          gender: _selectedGender!,
          hallName: _hallNameController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup Successful! Please Login.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen(initialUserType: 'Campus User')),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hall Student Signup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _hallNameController,
                decoration: const InputDecoration(labelText: 'Hall Name', prefixIcon: Icon(Icons.home_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Hall Name is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rollNoController,
                decoration: const InputDecoration(labelText: 'Roll Number', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Roll Number is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.trim().endsWith('@mcc.edu.in')) return 'Email must end with @mcc.edu.in';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return 'Enter a valid 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.people_outline)),
                validator: (v) => (v == null || v.isEmpty) ? 'Gender is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.school_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Department is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'SIGN UP',
                onPressed: _handleSignup,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
