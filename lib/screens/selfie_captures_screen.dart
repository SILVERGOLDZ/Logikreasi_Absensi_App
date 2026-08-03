import 'dart:io';
import 'dart:ui' as ui;

import 'package:absensi_app/widgets/snackbar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

// WEB
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Halaman full-screen untuk mengambil selfie dan preview hasilnya.
/// Mengembalikan XFile jika user menekan "Gunakan Foto Ini",
/// atau null jika user membatalkan di titik manapun.
class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

enum _CameraState { loading, permissionDenied, permissionPermanentlyDenied, error, ready }

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  _CameraState _cameraState = _CameraState.loading;
  bool _isBusy = false;

  XFile? _capturedPhoto;
  Size? _capturedPhotoSize;

  // Supaya waktu balik dari halaman Settings, izin kamera dicek ulang
  // otomatis tanpa user harus tap apapun lagi.
  bool _wasAwaitingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wasAwaitingSettings) {
      _wasAwaitingSettings = false;
      _setupCamera();
    }
  }

  // ==================== IZIN & INIT KAMERA (WAJIB) ====================
  Future<void> _setupCamera() async {
    setState(() => _cameraState = _CameraState.loading);

    final granted = await _ensureCameraPermission();
    if (!mounted) return;

    if (!granted) {
      // _ensureCameraPermission sudah set _cameraState yang sesuai
      // (permissionDenied / permissionPermanentlyDenied).
      return;
    }

    await _initCamera();
  }

  /// Return true kalau izin kamera granted. Kalau tidak, set
  /// _cameraState yang sesuai supaya UI menampilkan tombol yang tepat
  /// (Coba Lagi / Buka Pengaturan) — user WAJIB allow untuk lanjut.
  Future<bool> _ensureCameraPermission() async {
    // Web: tidak ada permission_handler. Browser sudah menampilkan dialog
    // izin sendiri saat CameraController.initialize() dipanggil (getUserMedia).
    // Kalau user tolak, exception akan tertangkap di _initCamera() -> _CameraState.error.
    if (kIsWeb) return true;

    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (!mounted) return false;
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      setState(() => _cameraState = _CameraState.permissionPermanentlyDenied);
      return false;
    }

    setState(() => _cameraState = _CameraState.permissionDenied);
    return false;
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      final frontCamera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      // screen.orientation.lock() tidak didukung browser di luar mode
      // fullscreen/PWA installed -> skip di web, wajib untuk mobile.
      if (!kIsWeb) {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      }

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _cameraState = _CameraState.ready;
      });
    } catch (e) {
      print("DEBUG camera init error: $e");
      if (!mounted) return;
      setState(() => _cameraState = _CameraState.error);
    }
  }

  Future<Size> _getImageDimensions(XFile file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final photo = await _controller!.takePicture();
      final size = await _getImageDimensions(photo);

      if (!mounted) return;
      setState(() {
        _capturedPhoto = photo;
        _capturedPhotoSize = size;
        _isBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      showErrorSnackBar(context, "Gagal mengambil foto");
    }
  }

  void _retake() {
    setState(() {
      _capturedPhoto = null;
      _capturedPhotoSize = null;
    });
  }

  void _confirm() => Navigator.pop(context, _capturedPhoto);

  void _cancel() => Navigator.pop(context, null);

  Future<void> _openAppSettingsAndWait() async {
    _wasAwaitingSettings = true;
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_capturedPhoto == null ? "Ambil Selfie" : "Preview Selfie"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_cameraState) {
      case _CameraState.loading:
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      case _CameraState.permissionDenied:
        return _buildPermissionMessage(
          message:
          "Aplikasi memerlukan izin kamera untuk mengambil selfie absensi.",
          actionLabel: "Izinkan Kamera",
          onAction: _setupCamera,
        );
      case _CameraState.permissionPermanentlyDenied:
        return _buildPermissionMessage(
          message:
          "Izin kamera ditolak permanen. Aktifkan izin kamera lewat Pengaturan aplikasi untuk bisa absen.",
          actionLabel: "Buka Pengaturan",
          onAction: _openAppSettingsAndWait,
        );
      case _CameraState.error:
        return _buildPermissionMessage(
          message: "Gagal mengakses kamera. Coba lagi.",
          actionLabel: "Coba Lagi",
          onAction: _setupCamera,
        );
      case _CameraState.ready:
        return _capturedPhoto == null ? _buildCameraView() : _buildPreviewView();
    }
  }

  Widget _buildPermissionMessage({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            // Controller melaporkan aspectRatio dalam orientasi natural
            // (landscape) sensor, jadi untuk tampilan portrait perlu dibalik.
            child: AspectRatio(
              aspectRatio: 1 / controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: _isBusy
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    final size = _capturedPhotoSize!;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: size.width / size.height,
              child: _buildPhotoPreview(_capturedPhoto!),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Pastikan wajah terlihat jelas sebelum melanjutkan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text("Ambil Ulang"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: const Text("Gunakan Foto Ini"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// XFile.path di web berupa blob URL, bukan path filesystem asli,
  /// jadi Image.file (dart:io) tidak bisa dipakai -> wajib Image.memory
  /// dari bytes untuk web. Mobile tetap Image.file (tidak diubah).
  Widget _buildPhotoPreview(XFile file) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          return Image.memory(snapshot.data!, fit: BoxFit.contain);
        },
      );
    }
    return Image.file(File(file.path), fit: BoxFit.contain);
  }
}