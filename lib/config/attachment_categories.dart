class AttachmentCategory {
  final String key;
  final String label;
  final String folderName;

  const AttachmentCategory({
    required this.key,
    required this.label,
    required this.folderName,
  });
}

const List<AttachmentCategory> kAttachmentCategories = [
  AttachmentCategory(key: 'leave', label: 'Cuti/Izin', folderName: 'leave_attachments'),
  AttachmentCategory(key: 'overtime', label: 'Lembur', folderName: 'overtime_attachments'),
  // tambah kategori baru di sini
];