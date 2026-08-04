import 'package:absensi_app/config/text_form_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:absensi_app/utils/title_case_helper.dart';

import '../../services/holiday_api.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar.dart';

class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() => _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen> {
  DateTime _focusedMonth = DateTime.now();
  List<dynamic> _holidays = [];
  bool _isLoading = false;

  Set<DateTime> get _activeHolidayDates {
    return _holidays
        .where((h) => h['isCancelled'] != true)
        .map((h) {
      final d = DateTime.parse(h['date']);
      return DateTime(d.year, d.month, d.day); // normalize, buang jam
    })
        .toSet();
  }

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    try {
      final data = await HolidayApi.list(
        year: _focusedMonth.year,
        month: _focusedMonth.month,
      );
      setState(() => _holidays = data);
    } catch (e) {
      if (mounted) showFloatingErrorSnackbar(context, 'Gagal memuat data hari libur');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
    _loadHolidays();
  }

  Future<void> _cancelHoliday(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan hari libur?'),
        content: const Text('Pengumuman terkait juga akan ditandai dibatalkan jika ini tanggal terakhir dalam batch-nya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await HolidayApi.cancel(id);
      if (mounted) showFloatingSuccessSnackbar(context, 'Hari libur dibatalkan');
      _loadHolidays();
    } catch (e) {
      if (mounted) showFloatingErrorSnackbar(context, 'Gagal membatalkan');
    }
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _HolidayFormSheet(
        existingDates: _activeHolidayDates,
        onSaved: () {
          Navigator.pop(ctx);
          _loadHolidays();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Kelola Hari Libur')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(_focusedMonth),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _holidays.isEmpty
                    ? const Center(child: Text('Tidak ada hari libur bulan ini'))
                    : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                  itemCount: _holidays.length,
                  itemBuilder: (context, index) {
                    final h = _holidays[index];
                    final isCancelled = h['isCancelled'] == true;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.event_busy,
                          color: isCancelled ? Colors.grey : Colors.redAccent,
                        ),
                        title: Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(h['date'])),
                          style: TextStyle(
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            color: isCancelled ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(h['reason'] ?? '-'),
                        trailing: isCancelled
                            ? const Chip(label: Text('Dibatalkan'))
                            : DateTime.parse(h['date']).isBefore(DateTime.now().toLocal())? null
                            : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _cancelHoliday(h['id']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Libur'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HolidayFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Set<DateTime> existingDates;
  const _HolidayFormSheet({
    required this.onSaved,
    this.existingDates = const {},
  });

  @override
  State<_HolidayFormSheet> createState() => _HolidayFormSheetState();
}

class _HolidayFormSheetState extends State<_HolidayFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRange = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  DateTime _firstAvailableDate() {
    final today = DateTime.now();
    DateTime initial = DateTime(today.year, today.month, today.day);
    while (widget.existingDates.contains(initial)) {
      initial = initial.add(const Duration(days: 1));
    }
    return initial;
  }

  Future<void> _pickSingleDate() async {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _firstAvailableDate(),
      firstDate: todayNormalized,
      lastDate: DateTime(2035),
      selectableDayPredicate: (day) {
        final d = DateTime(day.year, day.month, day.day);
        return !widget.existingDates.contains(d);
      },
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _endDate = null;
    });
  }

  Future<void> _pickDateRange() async {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final initialRange = (_startDate != null && _endDate != null)
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : DateTimeRange(start: _firstAvailableDate(), end: _firstAvailableDate());

    final picked = await showDateRangePicker(
      context: context,
      firstDate: todayNormalized,
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
    });
  }

  void _pickDate() {
    if (_isRange) {
      _pickDateRange();
    } else {
      _pickSingleDate();
    }
  }

  List<DateTime> _datesInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(last)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      setState(() => _errorMessage = 'Tanggal wajib dipilih');
      return;
    }
    if (_isRange && _endDate == null) {
      setState(() => _errorMessage = 'Tanggal wajib dipilih');
      return;
    }

    // Validasi bentrok
    final datesToCheck = _isRange
        ? _datesInRange(_startDate!, _endDate!)
        : [_startDate!];
    final conflicts = datesToCheck
        .where((d) => widget.existingDates.contains(d))
        .toList();

    if (conflicts.isNotEmpty) {
      setState(() => _errorMessage = 'Tidak boleh ada libur di rentang tanggal yang dipilih');
      return; // stop sebelum hit API
    }

    setState(() => _isSubmitting = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      await HolidayApi.create(
        startDate: fmt.format(_startDate!),
        endDate: _isRange ? fmt.format(_endDate!) : null,
        reason: _reasonController.text.trim(),
        title: _titleController.text.toTitleCase().trim(),
        content: _contentController.text.trim(),
      );
      widget.onSaved();
    } catch (e) {
      if (e is DioException) {
        debugPrint("STATUS: ${e.response?.statusCode}");
        debugPrint("DATA: ${e.response?.data}");
      }
      if (mounted) showFloatingErrorSnackbar(context, 'Gagal menyimpan hari libur');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tambah Hari Libur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rentang tanggal (bulk)'),
                value: _isRange,
                onChanged: (v) => setState(() {
                  _isRange = v;
                  if (!v) _endDate = null;
                }),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: _isRange ? 'Tanggal (Rentang)' : 'Tanggal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate == null
                        ? 'Pilih tanggal${_isRange ? ' (bisa rentang)' : ''}'
                        : _isRange
                        ? (_endDate != null
                        ? '${fmt.format(_startDate!)} - ${fmt.format(_endDate!)}'
                        : fmt.format(_startDate!))
                        : fmt.format(_startDate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLength: TextFormConfig.shortTitle,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Jenis / Alasan Libur (mis. Cuti Bersama)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text('Pengumuman Otomatis', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: TextFormConfig.title,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Judul Pengumuman',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLength: TextFormConfig.largeContent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Isi Pengumuman',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Simpan & Publikasikan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}