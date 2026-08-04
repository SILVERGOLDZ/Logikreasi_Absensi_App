import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/approver_model.dart';
import '../../services/api.dart';

enum ManualAction { clockIn, clockOut, done }

const List<String> attendanceStatusOptions = [
  'HADIR', 'TERLAMBAT', 'ABSEN', 'SAKIT',
  'CUTI', 'IZIN', 'LIBUR', 'BELUM_ABSEN', 'LEMBUR',
];

class ManualAttendanceController extends ChangeNotifier {
  ApproverModel? selectedEmployee;
  DateTime selectedDate = DateTime.now();
  ManualAction action = ManualAction.clockIn;
  String status = 'HADIR';
  String reason = '';
  String employeeAttendanceStatus = '';

  bool isCheckingStatus = false;
  bool isSubmitting = false;
  String? errorMessage;

  bool _hasClockIn = false;
  bool _hasClockOut = false;

  bool get canClockIn => !_hasClockIn;
  bool get canClockOut => _hasClockIn && !_hasClockOut;
  bool get done => _hasClockIn && _hasClockOut;

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  void setEmployee(ApproverModel employee) {
    selectedEmployee = employee;
    notifyListeners();
    _refreshStatus();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
    _refreshStatus();
  }

  void setAction(ManualAction value) {
    action = value;
    notifyListeners();
  }

  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  void setReason(String value) => reason = value;

  Future<void> _refreshStatus() async {
    if (selectedEmployee == null) return;
    isCheckingStatus = true;
    notifyListeners();
    try {
      final response = await DioClient.dio.get(
        '/admin/attendance/status',
        queryParameters: {
          'userId': selectedEmployee!.id,
          'date': formattedDate,
        },
      );
      final data = response.data;
      _hasClockIn = data != null && data['clockIn'] != null;
      _hasClockOut = data != null && data['clockOut'] != null;
      employeeAttendanceStatus = data['status'];

      if (_hasClockIn && !_hasClockOut) {
        action = ManualAction.clockOut;
      } else if (!_hasClockIn) {
        action = ManualAction.clockIn;
      } else if (_hasClockIn && _hasClockOut) {
        action = ManualAction.done;
      }
    } catch (e) {
      _hasClockIn = false;
      _hasClockOut = false;
    } finally {
      isCheckingStatus = false;
      notifyListeners();
    }
  }

  Future<bool> submit() async {
    if (selectedEmployee == null) {
      errorMessage = 'Pilih karyawan terlebih dahulu';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (action == ManualAction.clockIn) {
        await DioClient.dio.post('/admin/attendance/clock-in', data: {
          'userId': selectedEmployee!.id,
          'date': formattedDate,
          'status': status,
          if (reason.trim().isNotEmpty) 'reason': reason.trim(),
        });
      } else {
        await DioClient.dio.post('/admin/attendance/clock-out', data: {
          'userId': selectedEmployee!.id,
          'date': formattedDate,
        });
      }
      await _refreshStatus();
      return true;
    } catch (e) {
      errorMessage = _extractError(e);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _extractError(Object e) {
    try {
      final dioError = e as dynamic;
      final message = dioError.response?.data?['message'];
      if (message is String) return message;
    } catch (_) {}
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}