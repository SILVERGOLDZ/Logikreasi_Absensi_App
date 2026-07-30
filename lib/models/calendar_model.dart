class DayInfo {
  final HolidayInfo? holiday;
  final List<LeaveEntry> leaves;

  DayInfo({this.holiday, this.leaves = const []});

  factory DayInfo.fromJson(Map<String, dynamic> json) => DayInfo(
    holiday: json['holiday'] != null ? HolidayInfo.fromJson(json['holiday']) : null,
    leaves: (json['leaves'] as List? ?? []).map((e) => LeaveEntry.fromJson(e)).toList(),
  );
}

class HolidayInfo {
  final int id;
  final String reason;
  final bool isCancelled;

  HolidayInfo({required this.id, required this.reason, required this.isCancelled});

  factory HolidayInfo.fromJson(Map<String, dynamic> json) => HolidayInfo(
    id: json['id'],
    reason: json['reason'] ?? '-',
    isCancelled: json['isCancelled'] ?? false,
  );
}

class LeaveEntry {
  final int userId;
  final String username;
  final String? photoUrl;
  final String role;
  final String status; // CUTI | IZIN
  final String? reason;

  LeaveEntry({
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.role,
    required this.status,
    this.reason,
  });

  factory LeaveEntry.fromJson(Map<String, dynamic> json) => LeaveEntry(
    userId: json['userId'],
    username: json['username'] ?? '-',
    photoUrl: json['photoUrl'],
    role: json['role'] ?? '-',
    status: json['status'] ?? 'CUTI',
    reason: json['reason'],
  );
}

class Employee {
  final int id;
  final String username;
  final String role;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.username,
    required this.role,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'],
    username: json['username'] ?? '-',
    role: json['role'] ?? '-',
    photoUrl: json['photoUrl'],
  );
}