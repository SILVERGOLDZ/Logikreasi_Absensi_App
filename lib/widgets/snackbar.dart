import 'dart:async';

import 'package:flutter/material.dart';

enum BannerType { error, warning, success, info }

/// Banner overlay yang menggantikan SnackBar.
///
/// Kenapa bukan SnackBar? SnackBar bawaan Flutter di-queue oleh
/// ScaffoldMessenger — kalau user tap tombol berkali-kali dan tiap tap
/// menghasilkan error, semua pesan itu akan antre dan muncul satu-satu
/// (lama & mengganggu). AppBanner ini selalu HANYA punya 1 entry aktif:
/// begitu ada banner baru, banner lama langsung dibuang & diganti.
class AppBanner {
  AppBanner._();

  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
      BuildContext context, {
        required String message,
        BannerType type = BannerType.error,
        Duration duration = const Duration(seconds: 3),
      }) {
    // Buang banner lama (kalau ada) sebelum pasang yang baru,
    // supaya tidak ada antrian sama sekali.
    _dismiss();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    final entry = OverlayEntry(
      builder: (_) => _BannerWidget(
        message: message,
        type: type,
        onDismiss: _dismiss,
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _BannerWidget extends StatefulWidget {
  final String message;
  final BannerType type;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (Color, IconData) _styleFor(BannerType type) {
    switch (type) {
      case BannerType.error:
        return (Colors.red.shade600, Icons.error_outline);
      case BannerType.warning:
        return (Colors.orange.shade700, Icons.warning_amber_rounded);
      case BannerType.success:
        return (Colors.green.shade600, Icons.check_circle_outline);
      case BannerType.info:
        return (Colors.blueGrey.shade700, Icons.info_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _styleFor(widget.type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < 0) widget.onDismiss();
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper lama dipertahankan supaya semua pemanggilan
/// `showErrorSnackBar(context, "...")` yang sudah ada di project
/// tetap jalan tanpa perlu diubah satu-satu.
void showErrorSnackBar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.error);
}

void showSuccessSnackBar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.success);
}

void showWarningSnackBar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.warning);
}