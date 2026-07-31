// controllers/admin/overtime_approval_controller.dart
//
// ASUMSI: mengikuti pola LeaveApprovalController (belum lihat source aslinya).

import 'package:flutter/material.dart';

import '../../models/overtime_model.dart';
import '../../services/api.dart'; // TODO: sesuaikan

class OvertimeApprovalController extends ChangeNotifier {
  List<OvertimeModel> pending = [];
  List<OvertimeModel> history = [];
  bool isLoadingPending = false;
  bool isLoadingHistory = false;

  Future<void> init() async {
    await Future.wait([fetchPending(), fetchHistory()]);
  }

  Future<void> fetchPending() async {
    isLoadingPending = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/overtime/pending');
      pending = (res.data as List).map((e) => OvertimeModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchPending error: $e');
    } finally {
      isLoadingPending = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/overtime/history');
      history = (res.data as List).map((e) => OvertimeModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<bool> approve(int overtimeId, {String? note}) async {
    try {
      await DioClient.dio.patch('/admin/overtime/$overtimeId/approve', data: {'note': note});
      await fetchPending();
      return true;
    } catch (e) {
      debugPrint('approve error: $e');
      return false;
    }
  }

  Future<bool> reject(int overtimeId, {String? note}) async {
    try {
      await DioClient.dio.patch('/admin/overtime/$overtimeId/reject', data: {'note': note});
      await fetchPending();
      return true;
    } catch (e) {
      debugPrint('reject error: $e');
      return false;
    }
  }
}