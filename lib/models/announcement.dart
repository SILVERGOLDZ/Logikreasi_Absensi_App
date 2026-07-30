class Announcement {
  final int id;
  final String title;
  final String content;
  final String createdByName;
  final DateTime createdAt;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdByName,
    required this.createdAt,
    required this.isRead,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json["id"],
      title: json["title"] ?? "-",
      content: json["content"] ?? "",
      createdByName: json["createdByName"] ?? "-",
      createdAt: DateTime.parse(json["createdAt"]),
      isRead: json["isRead"] ?? false,
    );
  }

  Announcement copyWith({bool? isRead}) => Announcement(
    id: id,
    title: title,
    content: content,
    createdByName: createdByName,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}