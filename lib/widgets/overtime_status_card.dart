import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/overtime_model.dart';

class OvertimeStatusCard extends StatelessWidget {
  const OvertimeStatusCard({super.key, required this.overtime, this.onTap});

  final OvertimeModel overtime;
  final VoidCallback? onTap;

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

  String _dateTimeLabel() {
    final start = DateTime.parse(overtime.startDate);
    final dateLabel = overtime.isRange
        ? '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(overtime.endDate))}'
        : DateFormat('dd MMM yyyy').format(start);
    return '$dateLabel • ${overtime.startTime}-${overtime.endTime}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(overtime.status);
    final rejector = overtime.rejector;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overtime.user != null) ...[
                Text(overtime.user!.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      overtime.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(_statusLabel(overtime.status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(_dateTimeLabel(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.groups, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${overtime.approvedCount}/${overtime.totalApprovers} setuju', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  if (overtime.attachmentUrls.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.attach_file, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 2),
                    Text(
                      overtime.attachmentUrls.length > 1
                          ? '${overtime.attachmentUrls.length} lampiran'
                          : 'Lampiran',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
              if (rejector != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Ditolak oleh ${rejector.approverUsername}${rejector.note != null && rejector.note!.isNotEmpty ? ": ${rejector.note}" : ""}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: overtime.approvals.map((a) {
                  final c = a.status == 'approved' ? Colors.green : a.status == 'rejected' ? Colors.red : Colors.grey;
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: CircleAvatar(
                      radius: 10,
                      backgroundColor: c.withOpacity(0.15),
                      child: Icon(
                        a.status == 'approved' ? Icons.check : a.status == 'rejected' ? Icons.close : Icons.hourglass_empty,
                        size: 12,
                        color: c,
                      ),
                    ),
                    label: Text(a.approverUsername, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}