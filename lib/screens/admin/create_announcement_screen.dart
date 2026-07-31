import 'package:absensi_app/config/text_form_config.dart';
import 'package:flutter/material.dart';

import 'package:absensi_app/utils/title_case_helper.dart';

import '../../services/api.dart';
import '../../widgets/app_scaffold.dart';

class CreatePengumumanScreen extends StatefulWidget {
  const CreatePengumumanScreen({super.key});

  @override
  State<CreatePengumumanScreen> createState() => _CreatePengumumanScreenState();
}

class _CreatePengumumanScreenState extends State<CreatePengumumanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await DioClient.dio.post('/admin/announcement', data: {
        "title": _titleController.text.toTitleCase().trim(),
        "content": _contentController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengumuman berhasil dibuat")));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuat pengumuman")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text("Buat Pengumuman")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: TextFormConfig.title,
                decoration: const InputDecoration(
                    labelText: "Judul",
                    border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? "Judul wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLength: TextFormConfig.largeContent,
                decoration: const InputDecoration(
                  labelText: "Isi Pengumuman",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white
                ),
                maxLines: 8,
                validator: (value) => (value == null || value.trim().isEmpty) ? "Isi wajib diisi" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("Publikasikan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}