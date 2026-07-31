import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/approver_model.dart';
import '../models/leave_model.dart';
import '../services/api.dart';
import '../services/socket_service.dart';

class LeaveController extends ChangeNotifier {
  List<ApproverModel> approvers = [];
  List<LeaveModel> myLeaves = [];
  bool isLoadingApprovers = false;
  bool isLoadingLeaves = false;
  bool isSubmitting = false;
  String? errorMessage;

  StreamSubscription? _socketSub;

  Future<void> init() async {
    _socketSub = SocketService.instance.on('leaveStatusChanged').listen((_) => fetchMyLeaves());
    await Future.wait([fetchApprovers(), fetchMyLeaves()]);
  }

  Future<void> fetchApprovers() async {
    isLoadingApprovers = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/leave/approvers');
      approvers = (res.data as List).map((e) => ApproverModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchApprovers error: $e');
    }
    isLoadingApprovers = false;
    notifyListeners();
  }

  Future<void> fetchMyLeaves() async {
    isLoadingLeaves = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/leave/my');
      myLeaves = (res.data as List).map((e) => LeaveModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMyLeaves error: $e');
    }
    isLoadingLeaves = false;
    notifyListeners();
  }

  /// [attachment] opsional (PDF). Dikirim dalam 1 request multipart bareng field lain,
  /// field name file harus 'attachment' (sesuai upload.single('attachment') di backend).
  Future<bool> submitLeave({
    required String title,
    required String startDate,
    required String endDate,
    required String type,
    required String reason,
    required List<int> approverIds,
    List<File> attachments = const [],
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'title': title,
        'startDate': startDate,
        'endDate': endDate,
        'type': type,
        'reason': reason,
        'approverIds': jsonEncode(approverIds),
        'attachments': await Future.wait(
          attachments.map(
                (file) => MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        ),
      });

      await DioClient.dio.post('/leave', data: formData);
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('submitLeave error: $e');
      if (e is DioException) {
        debugPrint('Response: ${e.response?.data}');
        debugPrint('Status: ${e.response?.statusCode}');
      }
      errorMessage = 'Gagal mengajukan cuti. Coba lagi.';
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}