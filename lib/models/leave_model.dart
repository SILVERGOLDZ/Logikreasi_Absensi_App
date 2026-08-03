import 'approver_model.dart';

class LeaveApprovalModel {
  final int approverId;
  final String approverUsername;
  final String approverRole;
  final String? approverPhotoUrl;
  final String status; // pending | approved | rejected
  final String? note;

  LeaveApprovalModel({
    required this.approverId,
    required this.approverUsername,
    required this.approverRole,
    this.approverPhotoUrl,
    required this.status,
    this.note,
  });

  factory LeaveApprovalModel.fromJson(Map<String, dynamic> json) {
    final approver = json['approver'] ?? {};
    return LeaveApprovalModel(
      approverId: json['approverId'],
      approverUsername: approver['username'] ?? '-',
      approverRole: approver['role'] ?? '-',
      approverPhotoUrl: approver['photoUrl'],
      status: json['status'] ?? 'pending',
      note: json['note'],
    );
  }
}

class RequesterInfo {
  final int id;
  final String username;
  final String role;
  final String? photoUrl;

  RequesterInfo({required this.id, required this.username, required this.role, this.photoUrl});

  factory RequesterInfo.fromJson(Map<String, dynamic> json) => RequesterInfo(
    id: json['id'],
    username: json['username'] ?? '-',
    role: json['role'] ?? '-',
    photoUrl: json['photoUrl'],
  );
}

class LeaveModel {
  final int id;
  final String startDate;
  final String endDate;
  final String type; // CUTI | IZIN
  final String title;
  final String reason;
  final List<String> attachmentUrls;
  final String status; // pending | approved | rejected
  final List<LeaveApprovalModel> approvals;
  final RequesterInfo? user;

  LeaveModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.title,
    required this.reason,
    this.attachmentUrls = const [],
    required this.status,
    required this.approvals,
    this.user,
  });

  int get approvedCount => approvals.where((a) => a.status == 'approved').length;
  int get totalApprovers => approvals.length;
  bool get isRange => startDate != endDate;

  LeaveApprovalModel? get rejector {
    for (final a in approvals) {
      if (a.status == 'rejected') return a;
    }
    return null;
  }

  factory LeaveModel.fromJson(Map<String, dynamic> json) => LeaveModel(
    id: json['id'],
    startDate: json['startDate'],
    endDate: json['endDate'],
    type: json['type'] ?? 'CUTI',
    title: json['title'] ?? '-',
    reason: json['reason'] ?? '-',
    attachmentUrls: (json['attachmentUrls'] as List? ?? []).map((e) => e.toString()).toList(),
    status: json['status'] ?? 'pending',
    approvals: (json['approvals'] as List? ?? []).map((e) => LeaveApprovalModel.fromJson(e)).toList(),
    user: json['user'] != null ? RequesterInfo.fromJson(json['user']) : null,
  );
}