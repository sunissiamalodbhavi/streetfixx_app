import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult.any((result) => result != ConnectivityResult.none);
    if (!hasConnection) {
      throw Exception("No internet / server unreachable. Please check your connection.");
    }
  }

  static String get baseUrl => ApiConfig.baseUrl;
  static Duration get timeoutDuration => const Duration(seconds: ApiConfig.timeoutSeconds);

  // --- HTTP WRAPPERS ---
  
  Future<http.Response> _get(String url) async {
    await _checkConnectivity();
    print("API CALL → $url");
    try {
      final response = await http.get(Uri.parse(url)).timeout(timeoutDuration);
      print("STATUS → ${response.statusCode}");
      print("BODY → ${response.body}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception("Server waking up, please wait...");
    } on SocketException {
      throw Exception("No internet or server unreachable");
    } on Exception catch (e) {
      throw Exception("Unexpected error: $e");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    await _checkConnectivity();
    print("API CALL → $url");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(timeoutDuration);
      
      print("STATUS → ${response.statusCode}");
      print("BODY → ${response.body}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } on TimeoutException {
      throw Exception("Server waking up, please wait...");
    } on SocketException {
      throw Exception("No internet or server unreachable");
    } on Exception catch (e) {
      throw Exception("Unexpected error: $e");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  Future<http.Response> _put(String url, Map<String, dynamic> body) async {
    await _checkConnectivity();
    print("API CALL → $url");
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(timeoutDuration);
      
      print("STATUS → ${response.statusCode}");
      print("BODY → ${response.body}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } on TimeoutException {
      throw Exception("Server waking up, please wait...");
    } on SocketException {
      throw Exception("No internet or server unreachable");
    } on Exception catch (e) {
      throw Exception("Unexpected error: $e");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  Future<http.Response> _multipartPost(http.MultipartRequest request) async {
    await _checkConnectivity();
    print("API CALL → ${request.url}");
    try {
      final streamedsResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedsResponse);
      
      print("STATUS → ${response.statusCode}");
      print("BODY → ${response.body}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } on TimeoutException {
      throw Exception("Server waking up, please wait...");
    } on SocketException {
      throw Exception("No internet or server unreachable");
    } on Exception catch (e) {
      throw Exception("Unexpected error: $e");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // --- API METHODS ---

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String department,
    required String rollNo,
    required String gender,
    String? hallName,
    String? staffId,
  }) async {
    final response = await _post('$baseUrl/signup', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'department': department,
      'roll_no': rollNo,
      'gender': gender,
      'hall_name': hallName,
      'staff_id': staffId,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post('$baseUrl/login', {
      'email': email,
      'password': password,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> reportIssue({
    required int userId,
    required String title,
    required String description,
    required String category,
    required String location,
    double? latitude,
    double? longitude,
    File? imageFile,
    required String reporterType,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/report-issue'));
    
    request.fields['user_id'] = userId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['location'] = location;
    request.fields['reporter_type'] = reporterType;
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final response = await _multipartPost(request);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getCitizenIssues(int userId) async {
    final response = await _get('$baseUrl/citizen/issues/$userId');
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getAdminIssues({String? reporterType, String? role, String? status}) async {
    String url = '$baseUrl/admin/issues?';
    if (reporterType != null) {
      url += 'reporter_type=$reporterType&';
    }
    if (role != null) {
      url += 'role=$role&';
    }
    if (status != null) {
      url += 'status=$status&';
    }
    
    // Remove trailing ? or &
    if (url.endsWith('?') || url.endsWith('&')) {
      url = url.substring(0, url.length - 1);
    }
    
    final response = await _get(url);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminIssueCounts() async {
    final response = await _get('$baseUrl/admin/issues/counts');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminAnalytics() async {
    final response = await _get('$baseUrl/admin/analytics');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUsersCount() async {
    final response = await _get('$baseUrl/admin/users-count');
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getAdminBookings() async {
    final response = await _get('$baseUrl/admin/bookings');
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getStaffList() async {
    final response = await _get('$baseUrl/admin/staff');
    return jsonDecode(response.body);
  }

  Future<void> assignIssue(int issueId, int staffId) async {
    await _put('$baseUrl/admin/issue/assign', {
      'issue_id': issueId,
      'staff_id': staffId,
    });
  }

  Future<List<dynamic>> getMaintenanceIssues(int userId) async {
    final response = await _get('$baseUrl/maintenance/issues/$userId');
    return jsonDecode(response.body);
  }

  Future<void> updateIssueStatus(int issueId, String status, int userId) async {
    await _put('$baseUrl/maintenance/issue/update', {
      'issue_id': issueId,
      'status': status,
      'user_id': userId,
    });
  }

  Future<void> bookGuestHouse({
    required int userId,
    required String name,
    required String phone,
    required String department,
    required String guests,
    required String roomType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    await _post('$baseUrl/bookings', {
      'user_id': userId,
      'resource_type': 'Guest House',
      'resource_id': roomType,
      'start_time': fromDate,
      'end_time': toDate,
      'purpose': '$reason (Guests: $guests, Name: $name, Phone: $phone)',
    });
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    await _put('$baseUrl/bookings/status', {
      'booking_id': bookingId,
      'status': status,
    });
  }

  Future<void> completeIssue(int issueId, int maintenanceId, File imageFile, {String? completionNote}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/maintenance/complete_issue'));
    
    request.fields['issue_id'] = issueId.toString();
    request.fields['maintenance_id'] = maintenanceId.toString();
    if (completionNote != null) {
      request.fields['completion_note'] = completionNote;
    }

    request.files.add(await http.MultipartFile.fromPath('completion_image', imageFile.path));

    await _multipartPost(request);
  }

  Future<void> verifyIssue(int issueId, String status) async {
    await _put('$baseUrl/admin/verify_issue', {
      'issue_id': issueId,
      'status': status,
    });
  }

  Future<void> saveFcmToken(int userId, String token) async {
    await _post('$baseUrl/save_fcm_token', {
      'user_id': userId,
      'fcm_token': token,
    });
  }
}
