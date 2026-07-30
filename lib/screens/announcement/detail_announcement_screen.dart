import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/announcement_controller.dart';
import '../../models/announcement.dart';
import '../../widgets/app_scaffold.dart';

class DetailPengumumanScreen extends StatefulWidget {
  final int id;
  const DetailPengumumanScreen({super.key, required this.id});

  @override
  State<DetailPengumumanScreen> createState() => _DetailPengumumanScreenState();
}

class _DetailPengumumanScreenState extends State<DetailPengumumanScreen> {
  Announcement? _announcement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Lewat AnnouncementController, bukan Dio langsung: ini yang membuat
      // status "read" ter-sinkron otomatis ke HomeScreen & ListPengumumanScreen,
      // karena controller yang sama dipakai bertiga.
      final detail = await context.read<AnnouncementController>().loadDetail(widget.id);
      setState(() => _announcement = detail);
    } catch (e) {
      setState(() => _error = 'Gagal memuat pengumuman');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_announcement!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('oleh ${_announcement!.createdByName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Text(_announcement!.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }
}