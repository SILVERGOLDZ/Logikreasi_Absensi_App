import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/routes.dart';

bool _isNoInternetDialogShowing = false;

void showNoInternetDialog() {
  if (_isNoInternetDialogShowing) return;

  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  _isNoInternetDialogShowing = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tidak Ada Koneksi Internet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: const Text(
        'Aplikasi tidak dapat terhubung ke server. Anda bisa tetap menggunakan '
            'aplikasi, namun sebagian fitur mungkin tidak berfungsi.\n\n'
            'Jika koneksi sudah aktif kembali, restart aplikasi agar data '
            'ter-update dengan benar.',
        style: TextStyle(height: 1.4, fontSize: 13.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _isNoInternetDialogShowing = false;
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _isNoInternetDialogShowing = false;
                  _exitApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Restart', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _exitApp() {
  if (kIsWeb) return;
  if (Platform.isAndroid) {
    SystemNavigator.pop();
  } else {
    exit(0);
  }
}