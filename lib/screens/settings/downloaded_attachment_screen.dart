import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../config/attachment_categories.dart';

class DownloadedAttachmentsScreen extends StatefulWidget {
  const DownloadedAttachmentsScreen({super.key});

  @override
  State<DownloadedAttachmentsScreen> createState() => _DownloadedAttachmentsScreenState();
}

class _DownloadedAttachmentsScreenState extends State<DownloadedAttachmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: kAttachmentCategories.length, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Lampiran tersimpan'),
        bottom: kAttachmentCategories.length > 1
            ? TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: kAttachmentCategories.map((c) => Tab(text: c.label)).toList(),
        )
            : null,
      ),
      body: TabBarView(
        controller: _tab,
        children: kAttachmentCategories
            .map((category) => _CategoryAttachmentList(category: category))
            .toList(),
      ),
    );
  }
}
class _CategoryAttachmentList extends StatefulWidget {
  const _CategoryAttachmentList({required this.category});

  final AttachmentCategory category;

  @override
  State<_CategoryAttachmentList> createState() => _CategoryAttachmentListState();
}

class _CategoryAttachmentListState extends State<_CategoryAttachmentList> {
  bool _loading = true;
  List<File> _files = [];
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _attachmentDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/${widget.category.folderName}');
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final dir = await _attachmentDir();
      if (!await dir.exists()) {
        setState(() {
          _files = [];
          _totalBytes = 0;
          _loading = false;
        });
        return;
      }

      final entries = dir.listSync().whereType<File>().toList();
      entries.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      int total = 0;
      for (final f in entries) {
        total += f.lengthSync();
      }

      setState(() {
        _files = entries;
        _totalBytes = total;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus file')));
    }
  }

  Future<void> _confirmDeleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus file ini?'),
        content: Text(file.path.split('/').last),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteFile(file);
  }

  Future<void> _confirmDeleteAll() async {
    if (_files.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus semua lampiran ${widget.category.label}?'),
        content: Text('${_files.length} file akan dihapus permanen dari perangkat ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus semua', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dir = await _attachmentDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus file')));
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Belum ada lampiran ${widget.category.label.toLowerCase()} tersimpan', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_files.length} file · ${_formatSize(_totalBytes)} total',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              TextButton.icon(
                onPressed: _confirmDeleteAll,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                label: const Text('Hapus semua', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _files.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final file = _files[index];
              final sizeLabel = _formatSize(file.lengthSync());

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 22),
                ),
                title: Text(
                  file.path.split('/').last,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(sizeLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _confirmDeleteFile(file),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}