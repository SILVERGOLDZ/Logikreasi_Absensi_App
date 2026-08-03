import 'package:firebase_core/firebase_core.dart';

/// Config khusus WEB. Mobile (Android/iOS) tetap pakai konfigurasi native
/// (google-services.json / GoogleService-Info.plist) seperti sebelumnya —
/// file ini TIDAK dipakai di platform mobile.
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyBd4mV36_toqqVOXIpJhcYfLktpRWHB9hE",
  appId: "1:346154577484:web:e81ebfa994a47e50024ee9",
  messagingSenderId: "346154577484",
  projectId: "logikreasi-absensi",
  authDomain: "logikreasi-absensi.firebaseapp.com",
  storageBucket: "logikreasi-absensi.firebasestorage.app",
);

/// VAPID key untuk Web Push (dibutuhkan saat getToken() di web).
const String webVapidKey =
    "BPWQsWOoS9xzgAnnKXBoY4Exw5c1fMBtOu8ig04XaNRjaPPn4LdMeO2eeqIMdjW-yMHcxF-qY-Rg6Onx2IibjTg";