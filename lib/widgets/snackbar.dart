import 'dart:async';

import 'package:flutter/material.dart';

enum BannerType { error, warning, success, info }

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

void showFloatingErrorSnackbar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.error);
}

void showFloatingSuccessSnackbar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.success);
}

void showFloatingWarningSnackbar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.warning);
}

void showFloatingInfoSnackbar(BuildContext context, String message) {
  AppBanner.show(context, message: message, type: BannerType.info);
}

/// Widget feedback inline (non-floating) yang bisa dipasang langsung
/// di dalam layout page, mis. di atas form sebelum tombol submit.
///
/// Contoh pemakaian:
/// ```dart
/// if (_errorMessage != null) ...[
///   AppInlineFeedback(_errorMessage!, type: BannerType.error),
///   const SizedBox(height: 16),
/// ],
/// ```
class AppInlineFeedback extends StatelessWidget {
  final String message;
  final BannerType type;

  const AppInlineFeedback(
      this.message, {
        super.key,
        this.type = BannerType.error,
      });

  ({Color background, Color border, Color text}) _styleFor(BannerType type) {
    switch (type) {
      case BannerType.error:
        return (
        background: Colors.red.shade50,
        border: Colors.red.shade200,
        text: Colors.red.shade700,
        );
      case BannerType.warning:
        return (
        background: Colors.orange.shade50,
        border: Colors.orange.shade200,
        text: Colors.orange.shade700,
        );
      case BannerType.success:
        return (
        background: Colors.green.shade50,
        border: Colors.green.shade200,
        text: Colors.green.shade700,
        );
      case BannerType.info:
        return (
        background: Colors.blueGrey.shade50,
        border: Colors.blueGrey.shade200,
        text: Colors.blueGrey.shade700,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border),
      ),
      child: Text(
        message,
        style: TextStyle(color: style.text, fontSize: 13),
      ),
    );
  }
}

/// Varian inline feedback bertipe error.
///
/// Contoh pemakaian:
/// ```dart
/// if (_errorMessage != null) ...[
///   AppErrorInlineFeedback(_errorMessage!),
///   const SizedBox(height: 16),
/// ],
/// ```
class AppErrorInlineFeedback extends StatelessWidget {
  final String message;

  const AppErrorInlineFeedback(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppInlineFeedback(message, type: BannerType.error);
  }
}

/// Varian inline feedback bertipe warning.
class AppWarningInlineFeedback extends StatelessWidget {
  final String message;

  const AppWarningInlineFeedback(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppInlineFeedback(message, type: BannerType.warning);
  }
}

/// Varian inline feedback bertipe success.
class AppSuccessInlineFeedback extends StatelessWidget {
  final String message;

  const AppSuccessInlineFeedback(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppInlineFeedback(message, type: BannerType.success);
  }
}

/// Varian inline feedback bertipe info.
class AppInfoInlineFeedback extends StatelessWidget {
  final String message;

  const AppInfoInlineFeedback(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppInlineFeedback(message, type: BannerType.info);
  }
}