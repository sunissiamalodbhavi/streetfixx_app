import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  Future<User> login(String email, String password, String userType) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // MOCK LOGIN LOGIC
    // We trust the userType dropdown for this mock phase to direct navigation
    // In real backend, we would verify if the user actually has that role.
    
    // Map dropdown value to internal role string if needed, 
    // or just pass it through.
    // userType values: 'Student', 'Hostel Student', 'Staff', 'Quarters Resident', 'Admin'
    
    String roleKey = 'student';
    if (userType == 'Hostel Student') roleKey = 'hostel_student';
    else if (userType == 'Staff') roleKey = 'staff';
    else if (userType == 'Quarters Resident') roleKey = 'quarters_resident';
    else if (userType == 'Admin') roleKey = 'admin';

    return User(
      id: 1,
      role: roleKey,
      name: 'Mock User',
    );
  }

  Future<bool> signup(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
