import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';

import 'package:absensi_app/controllers/announcement_controller.dart';
import 'package:absensi_app/services/api.dart';
import 'package:absensi_app/services/auth/auth_service.dart';
import 'package:absensi_app/services/notification_service.dart';
import 'package:absensi_app/services/socket_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:absensi_app/config/routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (kIsWeb) {
    await Firebase.initializeApp(options: webFirebaseOptions);
    // onBackgroundMessage (top-level Dart handler) TIDAK didukung di web.
    // Background message di web ditangani oleh web/firebase-messaging-sw.js.
  } else {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await initializeDateFormatting();

  final authService = AuthService();

  //connect api
  DioClient.init(authService);
  //connect socket
  SocketService.instance.connect();

  await authService.loadFromStorage();

  if (authService.isAuthenticated) {
    NotificationService().init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProxyProvider<AuthService, AnnouncementController>(
          create: (_) => AnnouncementController(),
          update: (_, auth, controller) {
            final c = controller ?? AnnouncementController();
            c.updateUser(auth.userId);
            return c;
          },
        ),
      ],
      child: App(authService: authService),
    ),
  );
}

class App extends StatelessWidget {
  final AuthService authService;

  const App({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Agar bahasa lokal
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],

      title: 'Absensi App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
        ),
      ),
      routerConfig: createRouter(authService),
    );
  }
}