// models/overtime_model.dart
//
// Struktur mengikuti pola LeaveModel (lihat factory LeaveModel.fromJson).
//
// ASUMSI: RequesterInfo didefinisikan di leave_model.dart (satu file dengan
// LeaveModel), karena itu pola umum. Kalau ternyata RequesterInfo ada di file
// terpisah (misal requester_info.dart), ganti baris import di bawah ini saja
// — sisanya tidak perlu berubah.

import 'leave_model.dart'; // TODO: sesuaikan kalau RequesterInfo ada di file lain

class OvertimeApprovalModel {
  final int approverId;
  final String approverUsername;
  final String? approverPhotoUrl;
  final String status; // pending | approved | rejected
  final String? note;

  OvertimeApprovalModel({
    required this.approverId,
    required this.approverUsername,
    this.approverPhotoUrl,
    required this.status,
    this.note,
  });

  factory OvertimeApprovalModel.fromJson(Map<String, dynamic> json) {
    final approver = json['approver'] as Map<String, dynamic>?;
    return OvertimeApprovalModel(
      approverId: json['approverId'] ?? approver?['id'],
      approverUsername: approver?['username'] ?? json['approverUsername'] ?? '',
      approverPhotoUrl: approver?['photoUrl'],
      status: json['status'] ?? 'pending',
      note: json['note'],
    );
  }
}

class OvertimeModel {
  final int id;
  final String title;
  final bool isRange;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String reason;
  final String compensationType;
  final String status; // pending | approved | rejected
  final List<String> attachmentUrls;
  final List<OvertimeApprovalModel> approvals;
  final RequesterInfo? user;

  OvertimeModel({
    required this.id,
    required this.title,
    required this.isRange,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.compensationType,
    required this.status,
    required this.attachmentUrls,
    required this.approvals,
    this.user,
  });

  OvertimeApprovalModel? get rejector {
    try {
      return approvals.firstWhere((a) => a.status == 'rejected');
    } catch (_) {
      return null;
    }
  }

  int get approvedCount => approvals.where((a) => a.status == 'approved').length;
  int get totalApprovers => approvals.length;

  factory OvertimeModel.fromJson(Map<String, dynamic> json) => OvertimeModel(
    id: json['id'],
    title: json['title'] ?? '-',
    isRange: json['isRange'] ?? false,
    startDate: json['startDate'],
    endDate: json['endDate'],
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    reason: json['reason'] ?? '-',
    compensationType: json['compensationType'] ?? '-',
    status: json['status'] ?? 'pending',
    attachmentUrls: (json['attachmentUrls'] as List? ?? []).map((e) => e.toString()).toList(),
    approvals: (json['approvals'] as List? ?? []).map((e) => OvertimeApprovalModel.fromJson(e)).toList(),
    user: json['user'] != null ? RequesterInfo.fromJson(json['user']) : null,
  );
}