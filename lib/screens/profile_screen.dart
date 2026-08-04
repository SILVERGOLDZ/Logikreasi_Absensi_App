import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/auth/auth_service.dart';
import '../../config/routes.dart';
import '../services/api.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      _usernameController.text = user['username'] ?? '';
    }
  }

  // Upload Foto Profil
  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    final selectedImage = File(pickedFile.path);

    setState(() => _isUploading = true);

    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          selectedImage.path,
          filename: selectedImage.path.split('/').last,
        ),
      });

      final response = await DioClient.dio.post(
        '/user/profile-photo',
        data: formData,
      );

      if (response.statusCode == 200) {
        final auth = Provider.of<AuthService>(context, listen: false);

        await auth.login(auth.token!, response.data['user']);

        if (mounted) {
          setState(() {
            _imageFile = selectedImage;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto berhasil diupdate')),
          );
        }
      }
    } catch (e) {
      _showError('Gagal upload foto');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final String? photoUrl = user?['photoUrl'];

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (photoUrl != null ? NetworkImage("http://192.168.99.43:3001$photoUrl") : null),
                      child: (photoUrl == null && _imageFile == null) ? const Icon(Icons.person, size: 80) : null,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _isUploading
                          ? const CircularProgressIndicator()
                          : FloatingActionButton.small(onPressed: _pickAndUploadImage, child: const Icon(Icons.camera_alt)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    ListTile(leading: const Icon(Icons.badge), title: const Text("Username"), subtitle: Text(user?['username'] ?? '-')),
                    const Divider(),
                    ListTile(leading: const Icon(Icons.email), title: const Text("Email"), subtitle: Text(user?['email'] ?? '-')),
                    const Divider(),
                    ListTile(leading: const Icon(Icons.work), title: const Text("Role"), subtitle: Text(user?['role'] ?? 'user')),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Menu Lainnya
              Card(
                child: Column(
                  children: [
                    ListTile(
                        leading: const Icon(Icons.lock), title: const Text('Ubah Password'), trailing: const Icon(Icons.chevron_right), onTap: () {context.push('/settings/change-password');},
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifikasi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openAppSettings(),
                    ),
                    if(!kIsWeb)
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf), title: const Text('Hapus pdf tersimpan'), trailing: const Icon(Icons.chevron_right), onTap: () {context.push('/settings/downloaded');},
                      ),
                    ListTile(leading: const Icon(Icons.info), title: const Text('Tentang Aplikasi'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}