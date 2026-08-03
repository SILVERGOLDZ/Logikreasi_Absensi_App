import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/approver_model.dart';
import '../services/api.dart';

class EmployeePickerField extends StatelessWidget {
  const EmployeePickerField({
    super.key,
    required this.selected,
    required this.onChanged,
    this.label = 'Pilih Karyawan',
  });

  //pakai approver model karena kebetulan sama fieldnya
  final ApproverModel? selected;
  final ValueChanged<ApproverModel> onChanged;
  final String label;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<ApproverModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _EmployeePickerSheet(),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = selected?.photoUrl != null && selected!.photoUrl!.isNotEmpty;

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selected == null
            ? const Text('Cari & pilih karyawan...', style: TextStyle(color: Colors.grey))
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: hasPhoto ? NetworkImage(AppConfig.photoUrl(selected!.photoUrl)) : null,
              child: hasPhoto ? null : Text(selected!.username[0].toUpperCase(), style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Text(selected!.username),
          ],
        ),
      ),
    );
  }
}

class _EmployeePickerSheet extends StatefulWidget {
  const _EmployeePickerSheet();

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ApproverModel> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetch(value.trim()));
  }

  Future<void> _fetch(String search) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await DioClient.dio.get(
        '/user',
        queryParameters: search.isEmpty ? null : {'search': search},
      );
      final data = (response.data as List).map((e) => ApproverModel.fromJson(e)).toList();
      if (!mounted) return;
      setState(() => _results = data);
    } catch (e) {
      debugPrint('EmployeePicker fetch error: $e');
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat daftar karyawan');
    }finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Karyawan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Cari nama karyawan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: _isLoading
                  ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                  : _error != null
                  ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _results.isEmpty
                  ? const Padding(padding: EdgeInsets.all(24), child: Text('Karyawan tidak ditemukan'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final u = _results[index];
                  final hasPhoto = u.photoUrl != null && u.photoUrl!.isNotEmpty;
                  return ListTile(
                    onTap: () => Navigator.pop(context, u),
                    leading: CircleAvatar(
                      backgroundImage: hasPhoto ? NetworkImage(AppConfig.photoUrl(u.photoUrl)) : null,
                      child: hasPhoto ? null : Text(u.username[0].toUpperCase()),
                    ),
                    title: Text(u.username),
                    subtitle: Text(u.role),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}