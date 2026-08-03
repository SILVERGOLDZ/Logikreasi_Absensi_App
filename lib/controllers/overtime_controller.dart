import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/approver_model.dart';
import '../models/overtime_model.dart';
import '../services/api.dart';

class OvertimeController extends ChangeNotifier {
  List<ApproverModel> approvers = [];
  bool isLoadingApprovers = false;

  List<OvertimeModel> myOvertimes = [];
  bool isLoadingOvertimes = false;

  bool isSubmitting = false;
  String? errorMessage;

  Future<void> init() async {
    await Future.wait([fetchApprovers(), fetchMyOvertimes()]);
  }

  Future<void> fetchApprovers() async {
    isLoadingApprovers = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/overtime/approvers');
      approvers = (res.data as List).map((e) => ApproverModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchApprovers error: $e');
    } finally {
      isLoadingApprovers = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyOvertimes() async {
    isLoadingOvertimes = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/overtime/my');
      myOvertimes = (res.data as List)
          .map((e) => OvertimeModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('fetchMyOvertimes error: $e');
    } finally {
      isLoadingOvertimes = false;
      notifyListeners();
    }
  }

  Future<bool> submitOvertime({
    required bool isRange,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    required String title,
    required String reason,
    required String compensationType,
    required List<int> approverIds,
    List<File> attachments = const [],
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'isRange': isRange.toString(),
        'startDate': startDate,
        'endDate': endDate,
        'startTime': startTime,
        'endTime': endTime,
        'title': title,
        'reason': reason,
        'compensationType': compensationType,
        'approverIds': jsonEncode(approverIds),
        'attachments': await Future.wait(
          attachments.map((f) => MultipartFile.fromFile(f.path)),
        ),
      });

      await DioClient.dio.post('/overtime', data: formData);
      await fetchMyOvertimes();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}