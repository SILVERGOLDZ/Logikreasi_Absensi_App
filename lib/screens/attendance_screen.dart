import 'dart:io';

import 'package:absensi_app/screens/selfie_captures_screen.dart';
import 'package:absensi_app/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

import '../services/api.dart';
import '../services/auth/auth_service.dart';
import '../widgets/app_scaffold.dart';

// Web
import 'package:flutter/foundation.dart' show kIsWeb;

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ==================== STATE ====================
  String workTimeInterval = "";
  String status = "BELUM ABSEN";
  DateTime? clockInTime;
  DateTime? clockOutTime;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  bool isWithinOffice = false;
  bool _isProcessingAttendance = false;
  String? _processingLabel;

  final double officeLat = 3.597340;
  final double officeLng = 98.675091;
  final double allowedRadiusMeters = 100;

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _startLiveClock();
    _checkLocationSilently();
    _loadAttendanceStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
  }

  void _startLiveClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _currentTime = DateTime.now());
    });
  }

  // ==================== DATA ====================
  Future<void> _loadAttendanceStatus() async {
    try {
      final res = await DioClient.dio.get("/attendance/status");

      if (!mounted) return;

      setState(() {
        workTimeInterval = res.data["work_time_interval"];
        status = res.data["status"];

        if (res.data["clockIn"] != null) {
          clockInTime = DateTime.parse(res.data["clockIn"]).toLocal();
        }
        if (res.data["clockOut"] != null) {
          clockOutTime = DateTime.parse(res.data["clockOut"]).toLocal();
        }
      });
    } catch (err) {
      if (!mounted) return;
      showFloatingErrorSnackbar(context, "Gagal mengambil data absensi");
    }
  }

  /// Cek lokasi tanpa dialog apapun, cuma untuk badge "di luar radius
  /// kantor" di UI. Tidak dipakai untuk gate tombol — gate tombol
  /// dilakukan oleh [_ensureLocationReady] di [_handleClockInOut].
  Future<void> _checkLocationSilently() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled || !mounted) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final distance = Geolocator.distanceBetween(
        officeLat,
        officeLng,
        position.latitude,
        position.longitude,
      );

      setState(() => isWithinOffice = distance <= allowedRadiusMeters);
    } catch (_) {
      // Diam-diam saja, ini cuma untuk badge info.
    }
  }

  /// Gate WAJIB sebelum absen: GPS harus hidup, izin harus granted.
  /// Dipanggil di SETIAP tap tombol Clock In/Out (bukan cuma sekali di
  /// initState), jadi kalau user tadinya deny, tap berikutnya akan
  /// re-request izin lagi.
  ///
  /// Return `Position` kalau siap, `null` kalau belum (dan sudah
  /// menampilkan banner/dialog yang relevan ke user).
  Future<Position?> _ensureLocationReady() async {
    // 1) GPS/location service wajib aktif.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return null;
    if (!serviceEnabled) {
      final openSettings = await _showPermissionDialog(
        title: "Aktifkan Lokasi",
        message:
        "Layanan lokasi (GPS) sedang mati. Aktifkan GPS untuk melanjutkan absensi.",
        actionLabel: "Buka Pengaturan Lokasi",
      );
      if (openSettings) await Geolocator.openLocationSettings();
      return null;
    }

    // 2) Izin lokasi wajib granted. Kalau denied, re-request tiap tap.
    var permission = await Geolocator.checkPermission();
    if (!mounted) return null;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return null;
    }

    if (permission == LocationPermission.denied) {
      showFloatingErrorSnackbar(context, "Izin lokasi ditolak, coba lagi");
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      final openSettings = await _showPermissionDialog(
        title: "Izin Lokasi Diperlukan",
        message:
        "Izin lokasi ditolak permanen. Aktifkan izin lokasi lewat Pengaturan aplikasi untuk bisa absen.",
        actionLabel: "Buka Pengaturan",
      );
      if (openSettings) await Geolocator.openAppSettings();
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return null;
      return position;
    } catch (_) {
      if (!mounted) return null;
      showFloatingErrorSnackbar(context, "Gagal mendapatkan lokasi, coba lagi");
      return null;
    }
  }

  /// Dialog generic untuk minta user buka Settings (lokasi/app).
  /// Return true kalau user tap tombol aksi, false kalau Batal.
  Future<bool> _showPermissionDialog({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ==================== DIALOG: ALASAN CLOCK OUT DINI ====================
  Future<String?> _showEarlyClockOutDialog() async {
    final reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Clock Out Dini"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Anda akan clock out lebih awal.\nMohon tulis alasan Anda:",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Contoh: Ada keperluan keluarga, meeting mendadak, dll",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                showFloatingErrorSnackbar(context, "Alasan harus diisi");
                return;
              }
              Navigator.pop(context, reason);
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  // ==================== AMBIL SELFIE (pindah ke page terpisah) ====================
  Future<XFile?> _captureSelfieWithPreview() async {
    return Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()),
    );
  }

  // ==================== DIALOG: KONFIRMASI FINAL ====================
  /// Menampilkan ringkasan sebelum data dikirim ke server.
  /// Foto ditampilkan dengan aspect ratio ASLI (tidak di-crop/di-shrink jadi
  /// kotak), dibatasi tinggi maksimum agar dialog tidak overflow di layar kecil.
  Future<bool> _showFinalConfirmDialog({
    required bool isClockIn,
    required XFile selfie,
    String? reason,
  }) async {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    final bytes = await selfie.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);
    final aspectRatio = decodedImage.width / decodedImage.height;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isClockIn ? "Konfirmasi Clock In" : "Konfirmasi Clock Out"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: kIsWeb
                          ? Image.memory(bytes, fit: BoxFit.contain)
                          : Image.file(File(selfie.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _confirmRow("Aksi", isClockIn ? "Clock In" : "Clock Out"),
              _confirmRow("Tanggal", formattedDate),
              _confirmRow("Waktu", formattedTime),
              if (reason != null) _confirmRow("Alasan", reason),
              const SizedBox(height: 8),
              const Text(
                "Data ini akan disimpan dan tidak dapat diubah setelah dikirim. Lanjutkan?",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isClockIn ? Colors.green : Colors.red,
            ),
            child: Text(isClockIn ? "Ya, Clock In" : "Ya, Clock Out"),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          const Text(": "),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ==================== FLOW UTAMA CLOCK IN/OUT ====================
  Future<void> _handleClockInOut() async {
    if (_isProcessingAttendance) return;

    final isClockIn = clockInTime == null;
    final isClockOut = clockInTime != null && clockOutTime == null;
    if (!isClockIn && !isClockOut) return;

    setState(() {
      _isProcessingAttendance = true;
      _processingLabel = "Cek lokasi saat ini...";
    });

    try {
      // 0. Lokasi WAJIB: GPS hidup + izin granted, dicek ulang tiap tap.
      final position = await _ensureLocationReady();
      if (!mounted || position == null) return;

      final distance = Geolocator.distanceBetween(
        officeLat,
        officeLng,
        position.latitude,
        position.longitude,
      );
      final withinOffice = distance <= allowedRadiusMeters;
      setState(() => isWithinOffice = withinOffice);

      if (!withinOffice) {
        showFloatingErrorSnackbar(context, "Anda berada di luar radius kantor");
        return;
      }

      setState(() => _processingLabel = null);

      // 1. Ambil selfie (page terpisah, sudah termasuk retake, preview,
      //    & wajib izin kamera).
      final selfieToSend = await _captureSelfieWithPreview();
      if (!mounted) return;

      if (selfieToSend == null) {
        showFloatingErrorSnackbar(context, "Selfie dibatalkan");
        return;
      }

      // 2. Alasan clock out dini (jika perlu)
      String? reason;
      if (isClockOut) {
        const workEndHour = 17;
        if (DateTime.now().hour < workEndHour) {
          reason = await _showEarlyClockOutDialog();
          if (!mounted) return;
          if (reason == null) return;
        }
      }

      // 3. Konfirmasi final
      final confirmed = await _showFinalConfirmDialog(
        isClockIn: isClockIn,
        selfie: selfieToSend,
        reason: reason,
      );
      if (!mounted) return;
      if (!confirmed) return;

      // 4. Kirim ke server
      try {
        final selfieBytes = await selfieToSend.readAsBytes();
        final formData = FormData.fromMap({
          'selfie': MultipartFile.fromBytes(
            selfieBytes,
            filename: "selfie_${DateTime.now().millisecondsSinceEpoch}.jpg",
          ),
          if (reason != null) 'reason': reason,
        });

        if (isClockIn) {
          final res = await DioClient.dio.post("/attendance/clock-in", data: formData);
          if (!mounted) return;
          setState(() {
            clockInTime = DateTime.parse(res.data["clockIn"]).toLocal();
            status = res.data["status"];
          });
          showFloatingSuccessSnackbar(context, "Clock in berhasil");
        } else {
          final res = await DioClient.dio.post("/attendance/clock-out", data: formData);
          if (!mounted) return;
          setState(() {
            clockOutTime = DateTime.parse(res.data["clockOut"]).toLocal();
            status = res.data["status"] ?? "HADIR";
          });
          showFloatingSuccessSnackbar(context, "Clock out berhasil");
        }
      } on DioException catch (e) {
        if (!mounted) return;
        final data = e.response?.data;
        final message = data?["message"] ?? data?["error"] ?? "Terjadi kesalahan";
        showFloatingErrorSnackbar(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAttendance = false;
          _processingLabel = null;
        });
      }
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_currentTime);
    final formattedTime = DateFormat('HH:mm:ss').format(_currentTime);

    final canClockIn = clockInTime == null;
    final canClockOut = clockInTime != null && clockOutTime == null;
    final displayStatus = clockInTime == null
        ? status
        : clockOutTime == null
        ? "Sedang Bekerja" : "Selesai Bekerja";

    return AppScaffold(
      appBar: AppBar(
        title: Text("${auth.username}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workTimeInterval,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      "Clock In",
                      clockInTime != null ? DateFormat('HH:mm').format(clockInTime!) : "-",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      "Clock Out",
                      clockOutTime != null ? DateFormat('HH:mm').format(clockOutTime!) : "-",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: displayStatus == "Sedang Bekerja" ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: displayStatus == "Sedang Bekerja" ? Colors.green : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (canClockIn || canClockOut) && !_isProcessingAttendance
                      ? _handleClockInOut
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canClockIn ? Colors.greenAccent : Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessingAttendance
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _processingLabel ?? "Memproses...",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canClockIn
                            ? "CLOCK IN"
                            : canClockOut
                            ? "CLOCK OUT"
                            : "Absensi Selesai",
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 25),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isWithinOffice)
                const Center(
                  child: Text(
                    "⚠️ Anda berada di luar radius kantor",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}