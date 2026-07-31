import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api.dart';
import '../services/socket_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({this.isAdmin = false}) {
    _subscribeToSocket();
    if (isAdmin) {
      _subscribeToLeaveSocket();
      _subscribeToOvertimeSocket();
    }
  }

  final bool isAdmin;

  List<Map<String, dynamic>> workingUsers = [];
  int pendingLeaveCount = 0;
  int pendingOvertimeCount = 0;

  StreamSubscription? _attendanceSub;
  StreamSubscription? _leaveSub;

  Future<void> init() async {
    await Future.wait([
      loadWorkingUsers(),
      if (isAdmin) ...[
        loadPendingLeaveCount(),
        loadPendingOvertimeCount(),
      ]
    ]);
  }

  void _subscribeToSocket() {
    _attendanceSub = SocketService.instance.on('attendanceChanged').listen((data) {
      if (data == null) return;
      if (data['action'] == 'clockIn') {
        if (!workingUsers.any((user) => user['userId'] == data['userId'])) {
          workingUsers.add(Map<String, dynamic>.from(data));
        }
      } else if (data['action'] == 'clockOut') {
        workingUsers.removeWhere((user) => user['userId'] == data['userId']);
      }
      notifyListeners();
    });
  }

  void _subscribeToLeaveSocket() {
    _leaveSub = SocketService.instance.on('leaveStatusChanged').listen((_) {
      loadPendingLeaveCount();
    });
  }

  Future<void> loadWorkingUsers() async {
    try {
      final response = await DioClient.dio.get('/attendance/working-now');
      if (response.statusCode == 200) {
        workingUsers = List<Map<String, dynamic>>.from(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal load working users: $e');
    }
  }

  Future<void> loadPendingLeaveCount() async {
    try {
      final response = await DioClient.dio.get('/admin/leave/pending');
      pendingLeaveCount = (response.data as List).length;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal load pending leave count: $e');
    }
  }

  void _subscribeToOvertimeSocket() {
    _leaveSub = SocketService.instance.on('overtimeStatusChanged').listen((_) {
      loadPendingOvertimeCount();
    });
  }

  Future<void> loadPendingOvertimeCount() async {
    try {
      final response = await DioClient.dio.get('/admin/overtime/pending');
      pendingOvertimeCount = (response.data as List).length;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal load pending leave count: $e');
    }
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _leaveSub?.cancel();
    super.dispose();
  }
}