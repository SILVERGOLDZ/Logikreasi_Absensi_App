import 'dart:io';
import 'package:absensi_app/config/text_form_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/overtime_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/approval_picker_field.dart';

class OvertimeFormScreen extends StatelessWidget {
  const OvertimeFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OvertimeController()..init(),
      child: const _OvertimeFormBody(),
    );
  }
}

class _OvertimeFormBody extends StatefulWidget {
  const _OvertimeFormBody();

  @override
  State<_OvertimeFormBody> createState() => _OvertimeFormBodyState();
}

class _OvertimeFormBodyState extends State<_OvertimeFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final _compensationController = TextEditingController();

  bool _isRange = false;
  DateTime? _singleDate;
  DateTimeRange? _dateRange;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<int> _selectedApproverIds = [];
  List<File> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    _compensationController.dispose();
    super.dispose();
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _singleDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => _singleDate = picked);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachments.addAll(
            result.files.where((f) => f.path != null).map((f) => File(f.path!)),
          );
        });
      }
    } catch (e) {
      debugPrint('pickFiles error: $e');
    }
  }

  String _formatTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _submit(OvertimeController controller) async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRange && _dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rentang tanggal')));
      return;
    }
    if (!_isRange && _singleDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih tanggal lembur')));
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih waktu mulai dan selesai')));
      return;
    }
    if (_selectedApproverIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 approver')));
      return;
    }

    final startDate = _isRange
        ? DateFormat('yyyy-MM-dd').format(_dateRange!.start)
        : DateFormat('yyyy-MM-dd').format(_singleDate!);
    final endDate = _isRange
        ? DateFormat('yyyy-MM-dd').format(_dateRange!.end)
        : startDate;

    final success = await controller.submitOvertime(
      isRange: _isRange,
      startDate: startDate,
      endDate: endDate,
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      title: _titleController.text.trim(),
      reason: _reasonController.text.trim(),
      compensationType: _compensationController.text.trim(),
      approverIds: _selectedApproverIds,
      attachments: _attachments,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan lembur berhasil dikirim')));
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage ?? 'Gagal mengajukan')));
    }
  }

  Widget _buildDatePicker() {
    if (_isRange) {
      return InkWell(
        onTap: _pickDateRange,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Rentang Tanggal',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            _dateRange == null
                ? 'Pilih rentang tanggal'
                : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
          ),
        ),
      );
    }
    return InkWell(
      onTap: _pickSingleDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tanggal',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _singleDate == null ? 'Pilih tanggal' : DateFormat('dd MMM yyyy').format(_singleDate!),
        ),
      ),
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickTime(true),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Jam Mulai',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.access_time),
              ),
              child: Text(_startTime == null ? '--:--' : _formatTime(_startTime!)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _pickTime(false),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Jam Selesai',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.access_time),
              ),
              child: Text(_endTime == null ? '--:--' : _formatTime(_endTime!)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lampiran (PDF, opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Tambah file'),
            ),
          ],
        ),
        if (_attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Belum ada file dipilih',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                final isLast = index == _attachments.length - 1;
                final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(0);

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
                      file.path.split('/').last,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('$sizeKb KB', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _attachments.removeAt(index)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OvertimeController>();

    return AppScaffold(
      appBar: AppBar(title: const Text('Ajukan Lembur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jenis Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Per Hari')),
                  ButtonSegment(value: true, label: Text('Rentang Tanggal')),
                ],
                selected: {_isRange},
                onSelectionChanged: (s) => setState(() => _isRange = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: TextFormConfig.title,
                decoration: InputDecoration(
                  labelText: 'Judul',
                  hintText: 'Contoh: Lembur closing laporan bulanan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTimeRow(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _compensationController,
                maxLength: TextFormConfig.title,
                decoration: InputDecoration(
                  labelText: 'Jenis Kompensasi',
                  hintText: 'Contoh: Uang Rp 150.000 / Libur pengganti 1 hari',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Jenis kompensasi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: TextFormConfig.smallContent,
                decoration: InputDecoration(
                  labelText: 'Alasan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildAttachmentList(),
              const SizedBox(height: 16),
              controller.isLoadingApprovers
                  ? const Center(child: CircularProgressIndicator())
                  : ApproverPickerField(
                approvers: controller.approvers,
                selectedIds: _selectedApproverIds,
                onChanged: (ids) => setState(() => _selectedApproverIds = ids),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting ? null : () => _submit(controller),
                  child: controller.isSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kirim Pengajuan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}