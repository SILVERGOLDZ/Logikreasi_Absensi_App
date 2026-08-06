// lib/services/auth/auth_service.dart
import 'dart:async';

import 'package:absensi_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../api.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  List<String> _approverRoles = [];
  bool _rolesValidated = false; // true hanya setelah berhasil dikonfirmasi backend

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  String? get username => _user?['username'];
  String? get email => _user?['email'];
  int? get userId => _user?['id'];
  String? get role => _user?['role'];

  List<String> get approverRoles => _approverRoles;

  // Fail-safe: selama belum tervalidasi ke backend, anggap BUKAN approver.
  bool get isApprover => _rolesValidated && role != null && _approverRoles.contains(role);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    final userStr = prefs.getString('user_info');
    if (userStr != null) {
      _user = jsonDecode(userStr);
    }

    if (_token != null && JwtDecoder.isExpired(_token!)) {
      await logout();
      return;
    }

    notifyListeners();
    if (_token != null) {
      unawaited(refreshUserFromBackend());
    }
  }

  /// Selalu validasi role & approverRoles langsung ke backend.
  Future<void> refreshUserFromBackend() async {
    try {
      final res = await DioClient.dio.get('/auth/me');
      _user = Map<String, dynamic>.from(res.data['user']);
      _approverRoles = List<String>.from(res.data['approverRoles'] ?? []);
      _rolesValidated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_info', jsonEncode(_user));

      notifyListeners();
    } catch (e) {
      debugPrint('AuthService.refreshUserFromBackend gagal: $e');
    }
  }

  Future<void> login(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _user = userData;

    await prefs.setString('auth_token', token);
    await prefs.setString('user_info', jsonEncode(userData));
    notifyListeners();

    // validasi ulang langsung ke /auth/me.
    await refreshUserFromBackend();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');

    await NotificationService.deleteToken();

    _token = null;
    _user = null;
    _approverRoles = [];
    _rolesValidated = false;
    notifyListeners();
  }

  Map<String, String> getAuthHeaders() {
    return _token != null ? {'Authorization': 'Bearer $_token'} : {};
  }
}