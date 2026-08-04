import 'dart:io';

import 'package:absensi_app/config/text_form_config.dart';
import 'package:absensi_app/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/download_progress_sheet.dart';
import '../../services/api.dart';


import '../../models/leave_model.dart';
import '../../widgets/app_scaffold.dart';

// web
import 'package:flutter/foundation.dart' show kIsWeb;


class LeaveDetailScreen extends StatefulWidget {
  const LeaveDetailScreen({
    super.key,
    required this.leave,
    this.canApprove = false,
    this.onApprove,
    this.onReject,
  });

  final LeaveModel leave;

  /// true kalau halaman ini dibuka dari tab Pending admin -> tampilkan tombol approve/reject.
  final bool canApprove;

  /// return true kalau berhasil, dipanggil dengan catatan (boleh kosong).
  final Future<bool> Function(String? note)? onApprove;
  final Future<bool> Function(String? note)? onReject;

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  bool _processing = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      default: return 'Pending';
    }
  }

  Future<void> _openAttachment(String url) async {
    final fileName = url.split('/').last;

    if (kIsWeb) {
      try {
        final uri = Uri.parse(url);
        final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
        if (!ok) throw Exception('launchUrl returned false');
      } catch (e) {
        debugPrint('Open attachment (web) error: $e');
        if (!mounted) return;
        showFloatingErrorSnackbar(context, "Gagal membuka lampiran");
      }
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/leave_attachments/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        await OpenFile.open(savePath);
        return;
      }

      await Directory('${dir.path}/leave_attachments').create(recursive: true);

      if (!mounted) return;

      final progressKey = GlobalKey<DownloadProgressSheetState>();

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => DownloadProgressSheet(key: progressKey, fileName: fileName),
      );

      await DioClient.dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progressKey.currentState?.updateProgress(received / total);
          }
        },
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await OpenFile.open(savePath);
    } catch (e) {
      debugPrint('Download error: $e');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showFloatingErrorSnackbar(context, "Gagal mengunduh lampiran");
    }
  }

  Future<void> _handleAction(Future<bool> Function(String? note)? action, String sheetTitle) async {
    final noteController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sheetTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: TextFormConfig.mediumContent,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Konfirmasi'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || action == null) return;

    setState(() => _processing = true);
    final success = await action(noteController.text.trim());
    if (!mounted) return;
    setState(() => _processing = false);

    if (success) {
      context.pop();
    } else {
      showFloatingErrorSnackbar(context, "Gagal memproses, coba lagi");
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = widget.leave;
    final color = _statusColor(leave.status);
    final rejector = leave.rejector;

    final dateLabel = leave.isRange
        ? '${DateFormat('dd MMM yyyy').format(DateTime.parse(leave.startDate))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(leave.endDate))}'
        : DateFormat('dd MMMM yyyy').format(DateTime.parse(leave.startDate));

    return AppScaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leave.user != null) ...[
              Text(leave.user!.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(leave.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabel(leave.status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.category_outlined, label: 'Jenis', value: leave.type),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Tanggal', value: dateLabel),
            const SizedBox(height: 12),
            const Text('Alasan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(leave.reason),
            const SizedBox(height: 16),
            if (leave.attachmentUrls.isNotEmpty) ...[
              const Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: leave.attachmentUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    final isLast = index == leave.attachmentUrls.length - 1;
                    final fileName = url.split('/').last;

                    return Container(
                      decoration: BoxDecoration(
                        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 20),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => _openAttachment(url),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Approval', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...leave.approvals.map((a) {
              final c = a.status == 'approved' ? Colors.green : a.status == 'rejected' ? Colors.red : Colors.grey;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: c.withOpacity(0.15),
                  child: Icon(
                    a.status == 'approved' ? Icons.check : a.status == 'rejected' ? Icons.close : Icons.hourglass_empty,
                    size: 14,
                    color: c,
                  ),
                ),
                title: Text(a.approverUsername),
                subtitle: (a.note != null && a.note!.isNotEmpty) ? Text(a.note!) : null,
              );
            }),
            if (rejector != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ditolak oleh ${rejector.approverUsername}${rejector.note != null && rejector.note!.isNotEmpty ? ": ${rejector.note}" : ""}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (widget.canApprove) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: _processing ? null : () => _handleAction(widget.onReject, 'Tolak Pengajuan'),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _processing ? null : () => _handleAction(widget.onApprove, 'Setujui Pengajuan'),
                      child: const Text(
                          'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}