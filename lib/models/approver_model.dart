class ApproverModel {
  final int id;
  final String username;
  final String role;
  final String? photoUrl;

  ApproverModel({required this.id, required this.username, required this.role, this.photoUrl});

  factory ApproverModel.fromJson(Map<String, dynamic> json) => ApproverModel(
    id: json['id'],
    username: json['username'] ?? '-',
    role: json['role'] ?? '-',
    photoUrl: json['photoUrl'],
  );
}