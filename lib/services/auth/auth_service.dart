// lib/services/auth/auth_service.dart
import 'package:absensi_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  String? get username => _user?['username'];
  String? get email => _user?['email'];
  int? get userId => _user?['id'];
  String? get role => _user?['role'];

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    final userStr = prefs.getString('user_info');
    if (userStr != null) {
      _user = jsonDecode(userStr);
    }

    // Cek apakah token expired
    if (_token != null && JwtDecoder.isExpired(_token!)) {
      await logout();
    }

    notifyListeners();
  }

  // Login Service
  Future<void> login(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _user = userData;

    await prefs.setString('auth_token', token);
    await prefs.setString('user_info', jsonEncode(userData));
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');

    await NotificationService.deleteToken();

    _token = null;
    _user = null;
    notifyListeners();
  }

  // Helper untuk dipakai di interceptor atau API call
  Map<String, String> getAuthHeaders() {
    return _token != null ? {'Authorization': 'Bearer $_token'} : {};
  }
}