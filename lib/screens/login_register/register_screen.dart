import 'package:absensi_app/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String baseUrl = "http://192.168.99.43:3001"; //temporary url TODO:

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      showFloatingErrorSnackbar(context, "Password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_info', jsonEncode(data['user']));

        if (mounted) context.go(AppRoutes.attendance);
      } else {
        showFloatingErrorSnackbar(context, "Registrasi gagal: ${response.body}");
      }
    } catch (e) {
      showFloatingErrorSnackbar(context, "Koneksi error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text('Buat Akun Baru', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),

                  TextFormField(controller: _emailController, decoration: const InputDecoration(filled: true,
                      fillColor: Colors.white,labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress, validator: (v) => v?.contains('@') ?? false ? null : 'Email tidak valid'),
                  const SizedBox(height: 16),

                  TextFormField(controller: _usernameController, decoration: const InputDecoration(filled: true,
                      fillColor: Colors.white,labelText: 'Username', prefixIcon: Icon(Icons.person)), validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null),
                  const SizedBox(height: 16),

                  TextFormField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(filled: true,
                      fillColor: Colors.white,labelText: 'Password', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (v) => (v?.length ?? 0) < 6 ? 'Minimal 6 karakter' : null),
                  const SizedBox(height: 16),

                  TextFormField(controller: _confirmPasswordController, obscureText: _obscureConfirm, decoration: InputDecoration(filled: true,
                      fillColor: Colors.white,labelText: 'Konfirmasi Password', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))), validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('DAFTAR'),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(), // Kembali ke Login
                    child: const Text('Sudah punya akun? Masuk'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}