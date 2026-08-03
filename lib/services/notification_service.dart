import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../config/routes.dart';
import 'api.dart';

//web
import 'package:flutter/foundation.dart' show kIsWeb;

import '../firebase_options.dart';
import 'notification/browser_notifier_stub.dart'
if (dart.library.html) 'notification/browser_notifier_web.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  static bool _listenerRegistered = false;
  static String? _lastSentToken;

  Future<void> init() async {
    try {
      if (kIsWeb) {
        await BrowserNotifier.requestPermission();
        BrowserNotifier.listenForClicks(_navigateByType);
        _registerForegroundListenerWeb();
      } else {
        await _initLocalNotifications();
        _registerForegroundListener();
        _registerNotificationTapListener();
      }

      final settings =
      await FirebaseMessaging.instance.requestPermission(provisional: true);

      print('Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _postToken();
      }

      _registerTokenRefreshListener();
      await _handleInitialMessage();
    } catch (e) {
      print('Gagal inisialisasi notifikasi: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      // dipanggil saat notifikasi lokal (yang muncul waktu app foreground) di-tap
      onDidReceiveNotificationResponse: (response) {
        final type = response.payload;
        if (type != null && type.isNotEmpty) {
          _navigateByType(type);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  // App SEDANG DIBUKA saat notif masuk -> tampilkan manual + gambar
  void _registerForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      final imageUrl =
          notification.android?.imageUrl ?? notification.apple?.imageUrl;
      final localImagePath =
      imageUrl != null ? await _downloadImage(imageUrl) : null;

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: localImagePath != null
                ? BigPictureStyleInformation(
              FilePathAndroidBitmap(localImagePath),
              largeIcon: FilePathAndroidBitmap(localImagePath),
            )
                : null,
          ),
          iOS: DarwinNotificationDetails(
            attachments: localImagePath != null
                ? [DarwinNotificationAttachment(localImagePath)]
                : null,
          ),
        ),
        payload: message.data['type'] as String?,
      );
    });
  }

  // Versi WEB dari foreground listener. Tidak pakai flutter_local_notifications
// (tidak support web) dan tidak download gambar ke disk — icon langsung
// pakai URL, browser yang fetch sendiri.
  void _registerForegroundListenerWeb() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      final imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;

      BrowserNotifier.show(
        title: notification.title ?? '',
        body: notification.body,
        imageUrl: imageUrl,
        type: message.data['type'] as String?,
      );
    });
  }

  // App di BACKGROUND, user tap notifikasi dari tray
  void _registerNotificationTapListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'] as String?;
      if (type != null) _navigateByType(type);
    });
  }

  // App TERMINATED (cold start) karena user tap notifikasi
  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    final type = initialMessage?.data['type'] as String?;
    if (type != null) _navigateByType(type);
  }

  void _navigateByType(String type) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'announcement':
        context.push(AppRoutes.announcement);
        break;
      case 'leave_submitted':
        context.push(AppRoutes.leaveApproval);
        break;
      case 'leave_approved':
      case 'leave_rejected':
        context.push(AppRoutes.leave);
        break;
      case 'overtime_submitted':
        context.push(AppRoutes.overtimeApproval);
        break;
      case 'overtime_approved':
      case 'overtime_rejected':
        context.push(AppRoutes.overtime);
        break;
    }
  }

  Future<String?> _downloadImage(String url) async {
    try {
      final dir = await getTemporaryDirectory();

      await _clearOldNotificationImages(dir);

      final filePath =
          '${dir.path}/notif_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Dio().download(url, filePath);
      return filePath;
    } catch (e) {
      print('Gagal download gambar notifikasi: $e');
      return null;
    }
  }

  Future<void> _clearOldNotificationImages(Directory dir) async {
    try {
      final files = dir.listSync().whereType<File>().where(
            (f) => p.basename(f.path).startsWith('notif_'),
      );
      for (final file in files) {
        try {
          await file.delete();
        } catch (_) {
        }
      }
    } catch (e) {
      print('Gagal bersihkan gambar notifikasi lama: $e');
    }
  }

  static Future<void> _postToken() async {
    try {
      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: webVapidKey)
          : await FirebaseMessaging.instance.getToken();

      if (token == null || token == _lastSentToken) return;

      await DioClient.dio.put('/notification/update-token', data: {
        'token': token,
      });
      _lastSentToken = token;
    } catch (e) {
      print("error update token: $e");
    }
  }

  static void _registerTokenRefreshListener() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await DioClient.dio.put('/notification/update-token', data: {
          'token': newToken,
        });
        _lastSentToken = newToken;
      } catch (e) {
        print("Gagal update token: $e");
      }
    });
  }

  static Future<void> deleteToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await DioClient.dio.delete('/notification/delete-token', data: {
          'token': token,
        });
      }
      await FirebaseMessaging.instance.deleteToken();
      _lastSentToken = null;
    } catch (e) {
      print("error delete token: $e");
    }
  }
}