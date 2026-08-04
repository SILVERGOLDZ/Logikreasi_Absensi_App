import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin/manual_attendance_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/employee_picker_field.dart';
import '../../widgets/snackbar.dart';

class ManualAttendanceScreen extends StatelessWidget {
  const ManualAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManualAttendanceController(),
      child: const _ManualAttendanceBody(),
    );
  }
}

class _ManualAttendanceBody extends StatefulWidget {
  const _ManualAttendanceBody();

  @override
  State<_ManualAttendanceBody> createState() => _ManualAttendanceBodyState();
}

class _ManualAttendanceBodyState extends State<_ManualAttendanceBody> {
  final _reasonController = TextEditingController();

  late final ManualAttendanceController _controller;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = context.read<ManualAttendanceController>();
    _controller.addListener(_syncLiveClock);
    _syncLiveClock(); // cek state awal, jaga-jaga kalau default action = clockOut
  }

  void _syncLiveClock() {
    if (_controller.action == ManualAction.clockOut) {
      _startLiveClock();
    } else {
      _stopLiveClock();
    }
  }

  void _startLiveClock() {
    if (_timer != null) return; // sudah jalan, jangan buat timer baru
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _currentTime = DateTime.now());
    });
  }

  void _stopLiveClock() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopLiveClock();
    _controller.removeListener(_syncLiveClock);
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(ManualAttendanceController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) controller.setDate(picked);
  }

  Future<void> _submit(ManualAttendanceController controller) async {
    final success = await controller.submit();
    if (!mounted) return;
    if (success) {
      showFloatingSuccessSnackbar(
        context,
        controller.action == ManualAction.clockIn ? 'Clock in manual berhasil' : 'Clock out manual berhasil',
      );
    } else {
      showFloatingErrorSnackbar(context, controller.errorMessage ?? 'Gagal memproses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ManualAttendanceController>();
    final formattedTime = DateFormat('HH:mm:ss').format(_currentTime);


    return AppScaffold(
      appBar: AppBar(title: const Text('Presensi Manual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Karyawan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            EmployeePickerField(
              selected: controller.selectedEmployee,
              onChanged: controller.setEmployee,
            ),
            const SizedBox(height: 16),
            const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDate(controller),
              child: InputDecorator(
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(controller.formattedDate),
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isCheckingStatus)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (controller.selectedEmployee != null && !controller.isCheckingStatus) ...[
              const Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<ManualAction>(
                segments: [
                  ButtonSegment(
                    value: ManualAction.clockIn,
                    label: const Text('Clock In Manual'),
                    enabled: controller.canClockIn,
                  ),
                  ButtonSegment(
                    value: ManualAction.clockOut,
                    label: const Text('Clock Out Manual'),
                    enabled: controller.canClockOut,
                  ),
                ],
                selected: {controller.action},
                onSelectionChanged: (s) => controller.setAction(s.first),
              ),
              if (controller.employeeAttendanceStatus == "CUTI") ...[
                SizedBox(height: 24,),
                AppErrorInlineFeedback("Karyawan berstatus CUTI pada tanggal tersebut.\nApa kamu yakin ingin mengubah status karyawan?"),
              ],
              if (!controller.canClockIn && !controller.canClockOut)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Karyawan sudah clock in & clock out pada tanggal tersebut',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              if (controller.action == ManualAction.clockIn) ...[
                const Text('Status Kehadiran', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: controller.status,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: attendanceStatusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setStatus(v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: controller.setReason,
                ),
                const SizedBox(height: 16),
              ],

              if(controller.action == ManualAction.clockOut) ...[
                Column(
                  children: [
                    Text("Anda akan melakukan Clock Out manual karyawan di jam berikut:", style: TextStyle(color: Colors.redAccent),),
                    SizedBox(height: 24,),
                    Center(
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          formattedTime,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24,),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (controller.canClockIn || controller.canClockOut) && !controller.isSubmitting
                      ? () => _submit(controller)
                      : null,
                  child: controller.isSubmitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    controller.action == ManualAction.clockIn ? 'Simpan Clock In Manual' : 'Simpan Clock Out Manual',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}