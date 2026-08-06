import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api.dart';
import '../services/socket_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({bool isAdmin = false}) : _isAdmin = isAdmin {
    _subscribeToSocket();
    if (_isAdmin) {
      _subscribeToLeaveSocket();
      _subscribeToOvertimeSocket();
    }
  }

  bool _isAdmin;
  bool get isAdmin => _isAdmin;

  List<Map<String, dynamic>> workingUsers = [];
  int pendingLeaveCount = 0;
  int pendingOvertimeCount = 0;

  StreamSubscription? _attendanceSub;
  StreamSubscription? _leaveSub;
  StreamSubscription? _overtimeSub;

  Future<void> init() async {
    await Future.wait([
      loadWorkingUsers(),
      if (_isAdmin) ...[
        loadPendingLeaveCount(),
        loadPendingOvertimeCount(),
      ]
    ]);
  }

  void setIsAdmin(bool value) {
    if (value == _isAdmin) return;

    _isAdmin = value;

    if (_isAdmin) {
      _subscribeToLeaveSocket();
      _subscribeToOvertimeSocket();
      loadPendingLeaveCount();
      loadPendingOvertimeCount();
    } else {
      _leaveSub?.cancel();
      _leaveSub = null;
      _overtimeSub?.cancel();
      _overtimeSub = null;
      pendingLeaveCount = 0;
      pendingOvertimeCount = 0;
    }

    notifyListeners();
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
    if (_leaveSub != null) return;
    _leaveSub = SocketService.instance.on('leaveStatusChanged').listen((_) {
      loadPendingLeaveCount();
    });
  }

  void _subscribeToOvertimeSocket() {
    if (_overtimeSub != null) return;
    _overtimeSub = SocketService.instance.on('overtimeStatusChanged').listen((_) {
      loadPendingOvertimeCount();
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
      final response = await DioClient.dio.get(
        '/admin/leave/pending',
        queryParameters: {'page': 1, 'limit': 1},
      );
      pendingLeaveCount = response.data['total'] as int;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal load pending leave count: $e');
    }
  }

  Future<void> loadPendingOvertimeCount() async {
    try {
      final response = await DioClient.dio.get(
        '/admin/overtime/pending',
        queryParameters: {'page': 1, 'limit': 1},
      );
      pendingOvertimeCount = response.data['total'] as int;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal load pending overtime count: $e');
    }
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _leaveSub?.cancel();
    _overtimeSub?.cancel();
    super.dispose();
  }
}