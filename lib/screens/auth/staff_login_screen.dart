import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../staff/staff_home.dart'; // Changed from staff_dashboard.dart
import 'staff_signup_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      // Check if the user is actually staff
      final role = response['role'].toString().toLowerCase().trim();
      
      if (role == 'staff') {
         final userId = response['user_id']; // Extract userId
         final name = response['name'];

         if (userId == null) {
            throw Exception('User ID invalid'); 
         }

         Navigator.pushReplacement(
           context,
           MaterialPageRoute(
             builder: (_) => StaffHome(
               userId: userId is int ? userId : int.parse(userId.toString()), 
               userName: name
             ),
           ),
         );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not a staff account')));
      }
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
      appBar: AppBar(title: const Text('Staff Login'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work, size: 80, color: Colors.teal),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 30),
            CustomButton( 
              text: 'Login',
              onPressed: _handleLogin,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StaffSignupScreen()),
              ),
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
