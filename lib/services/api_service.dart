import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class ApiService {
  // IMPORTANT: 127.0.0.1 only works on your computer.
  // Your computer's IP address is 192.168.8.184.
  static const String baseUrl = 'http://eliteinternationalschool-live.us.stackstaging.com/api';

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      debugPrint('Fetching user details from: ${Uri.parse('$baseUrl/user-details')}');
      // Try to parse userId to int if possible
      dynamic userIdPayload = userId;
      if (int.tryParse(userId) != null) {
        userIdPayload = int.parse(userId);
      }

      debugPrint('Payload: ${jsonEncode({'user_id': userIdPayload})}');

      final response = await http.post(
        Uri.parse('$baseUrl/user-details'),
        body: jsonEncode({'user_id': userIdPayload}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API Error: $e');
    }
    return null;
  }

  Future<String?> getLastAttendanceStatus(String userId) async {
    try {
      dynamic userIdPayload = userId;
      if (int.tryParse(userId) != null) {
        userIdPayload = int.parse(userId);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/attendence/user'),
        body: jsonEncode({'user_id': userIdPayload}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && (data['data'] as List).isNotEmpty) {
          return data['data'][0]['status']; // Return latest status
        }
      }
    } catch (e) {
      debugPrint('Error getting last status: $e');
    }
    return null; // Return null if no history or error
  }

  Future<bool> markAttendance({
    required String userId,
    required String status,
    required String time,
    required String date,
  }) async {
    try {
      dynamic userIdPayload = userId;
      if (int.tryParse(userId) != null) {
        userIdPayload = int.parse(userId);
      }

      final Map<String, dynamic> body = {
        'user_id': userIdPayload,
        'date': date,
        'status': status,
      };

      if (status == 'in') {
        body['in_time'] = time;
      } else {
        body['out_time'] = time;
      }

      debugPrint('Marking Attendance: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/attendence/mark'),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Mark Response Status: ${response.statusCode}');
      debugPrint('Mark Response Body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Mark API Error: $e');
      return false;
    }
  }

  Future<List<Attendance>> getAttendanceHistory() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    return [
      Attendance(
        id: '1',
        studentName: 'John Doe',
        studentId: 'STU001',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        status: 'Present',
        subject: 'Mathematics',
        location: 'Room 101',
      ),
      Attendance(
        id: '2',
        studentName: 'John Doe',
        studentId: 'STU001',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Late',
        subject: 'Physics',
        location: 'Lab 1',
      ),
      Attendance(
        id: '3',
        studentName: 'John Doe',
        studentId: 'STU001',
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        status: 'Present',
        subject: 'Computer Science',
        location: 'Room 202',
      ),
    ];
  }
}
