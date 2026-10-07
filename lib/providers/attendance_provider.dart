import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Attendance> _history = [];
  bool _isLoading = false;

  List<Attendance> get history => _history;
  bool get isLoading => _isLoading;

  int get totalPresent => _history.where((a) => a.status == 'Present').length;
  int get totalLate => _history.where((a) => a.status == 'Late').length;
  int get totalAbsent => _history.where((a) => a.status == 'Absent').length;

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _apiService.getUserDetails(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getLastAttendanceStatus(String userId) async {
    return await _apiService.getLastAttendanceStatus(userId);
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _apiService.getAttendanceHistory();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAttendance({
    required String userId,
    required String status,
    required String time,
    required String date,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _apiService.markAttendance(
        userId: userId,
        status: status,
        time: time,
        date: date,
      );
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
