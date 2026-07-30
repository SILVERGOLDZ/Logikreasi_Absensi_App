import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/leave_model.dart';
import '../../services/api.dart';
import '../../services/socket_service.dart';

class LeaveApprovalController extends ChangeNotifier {
  List<LeaveModel> pending = [];
  List<LeaveModel> history = [];
  bool isLoadingPending = false;
  bool isLoadingHistory = false;

  StreamSubscription? _socketSub;

  Future<void> init() async {
    _socketSub = SocketService.instance.on('leaveStatusChanged').listen((_) {
      fetchPending();
      fetchHistory();
    });
    await Future.wait([fetchPending(), fetchHistory()]);
  }

  Future<void> fetchPending() async {
    isLoadingPending = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/leave/pending');
      pending = (res.data as List).map((e) => LeaveModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchPending error: $e');
    }
    isLoadingPending = false;
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/leave/history');
      history = (res.data as List).map((e) => LeaveModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  Future<bool> approve(int leaveId, {String? note}) async {
    try {
      await DioClient.dio.post('/admin/leave/$leaveId/approve', data: {'note': note});
      await Future.wait([fetchPending(), fetchHistory()]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reject(int leaveId, {String? note}) async {
    try {
      await DioClient.dio.post('/admin/leave/$leaveId/reject', data: {'note': note});
      await Future.wait([fetchPending(), fetchHistory()]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}