import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/announcement_controller.dart';
import '../../models/announcement.dart';

class ListPengumumanScreen extends StatefulWidget {
  const ListPengumumanScreen({super.key});

  @override
  State<ListPengumumanScreen> createState() => _ListPengumumanScreenState();
}

class _ListPengumumanScreenState extends State<ListPengumumanScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // AnnouncementController itu sendiri sudah di-provide di root (main.dart),
    // di sini kita cuma minta dia (re)load halaman pertama untuk list ini.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementController>().loadListInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = context.read<AnnouncementController>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !controller.loadingList &&
        controller.hasMoreList) {
      controller.loadListMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = context.watch<AnnouncementController>();
    final items = announcements.listItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Berita'),
        actions: [
          TextButton(
            onPressed: announcements.unreadCount == 0
                ? null
                : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Tandai semua dibaca?'),
                  content: const Text('Semua pengumuman akan ditandai sebagai sudah dibaca.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<AnnouncementController>().markAllAsRead();
              }
            },
            child: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: announcements.refreshList,
          child: ListView.separated(
            controller: _scrollController,
            itemCount: items.length + (announcements.hasMoreList ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = items[index];
              return _AnnouncementListTile(item: item);
            },
          ),
        ),
      ),
    );
  }
}

class _AnnouncementListTile extends StatelessWidget {
  const _AnnouncementListTile({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: !item.isRead
          ? const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
        ),
      )
          : const SizedBox(width: 8),
      title: Text(
        item.title,
        style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: Text('oleh ${item.createdByName}'),
      trailing: Text(
        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () => context.push('/announcement/${item.id}'),
    );
  }
}