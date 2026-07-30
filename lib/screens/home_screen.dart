import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/home_controller.dart';
import '../models/announcement.dart';
import '../services/auth/auth_service.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController(
        isAdmin: Provider.of<AuthService>(context, listen: false).role == 'admin',
      )..init(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final Map<String, bool> _expanded = {};

  static const sections = ['Daftar Karyawan'];
  static const adminSections = <String>[];
  static const _liveEmployeeSections = {'Daftar Karyawan'};

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final home = context.watch<HomeController>();
    final announcements = context.watch<AnnouncementController>();
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final isSmallScreen = screenWidth < 360;

    return AppScaffold(
      appBar: AppBar(
        title: Text(auth.username ?? 'User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _MenuGrid(screenWidth: screenWidth, isAdmin: auth.role == 'admin'),
              const SizedBox(height: 24),
              if (auth.role == 'admin')
                ...adminSections.map((title) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SectionHeader(
                    title: title,
                    index: 'admin_${adminSections.indexOf(title)}',
                    isExpanded: _expanded['admin_${adminSections.indexOf(title)}'] ?? false,
                    isLiveEmployeeSection: _liveEmployeeSections.contains(title),
                    workingUsersCount: home.workingUsers.length,
                    onToggle: (key) => setState(() => _expanded[key] = !(_expanded[key] ?? false)),
                    workingUsersBuilder: () => _WorkingUsersList(workingUsers: home.workingUsers),
                  ),
                )),
              ...sections.map((title) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SectionHeader(
                  title: title,
                  index: 'user_${sections.indexOf(title)}',
                  isExpanded: _expanded['user_${sections.indexOf(title)}'] ?? false,
                  isLiveEmployeeSection: _liveEmployeeSections.contains(title),
                  workingUsersCount: home.workingUsers.length,
                  onToggle: (key) => setState(() => _expanded[key] = !(_expanded[key] ?? false)),
                  workingUsersBuilder: () => _WorkingUsersList(workingUsers: home.workingUsers),
                ),
              )),
              const SizedBox(height: 8),
              _PengumumanSection(controller: announcements),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.screenWidth, required this.isAdmin});

  final double screenWidth;
  final bool isAdmin;

  static int _crossAxisCount(double width) {
    if (width < 360) return 3;
    if (width < 600) return 4;
    return 5;
  }

  static double _aspectRatio(double width) {
    if (width < 360) return 0.75;
    if (width < 480) return 0.85;
    if (width < 600) return 0.95;
    return 1.05;
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _crossAxisCount(screenWidth),
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: _aspectRatio(screenWidth),
          children: [
            _MenuItem(icon: Icons.access_time, label: 'Cuti', color: Colors.redAccent, screenWidth: screenWidth, onTap: () => context.push('/leave'),),
            _MenuItem(icon: Icons.nights_stay_rounded, label: 'Lembur', color: Colors.grey.shade300, screenWidth: screenWidth),
            _MenuItem(icon: Icons.home_work, label: 'Perbaikan\nKehadiran', color: Colors.grey.shade300, screenWidth: screenWidth),
            _MenuItem(icon: Icons.people, label: 'Perubahan\nShift', color: Colors.grey.shade300, screenWidth: screenWidth),
            _MenuItem(icon: Icons.access_time, label: 'Kehadiran\nManual', color: Colors.grey.shade300, screenWidth: screenWidth),
            _MenuItem(icon: Icons.payment, label: 'Kasbon', color: Colors.grey.shade300, screenWidth: screenWidth),
            _MenuItem(icon: Icons.money, label: 'Reimburse', color: Colors.grey.shade300, screenWidth: screenWidth),
            if (isAdmin)...[
              _MenuItem(
                icon: Icons.speaker_phone_outlined,
                label: 'Buat\nBerita',
                color: Colors.blue,
                screenWidth: screenWidth,
                onTap: () => context.push('/admin/announcement/create'),
              ),
              _MenuItem(icon: Icons.free_breakfast_rounded, label: 'Tetapkan\nLibur', color: Colors.brown, screenWidth: screenWidth, onTap: () => context.push('/admin/holiday')),
              _MenuItem(
                icon: Icons.fact_check,
                label: 'Approve\ncuti',
                color: Colors.redAccent,
                screenWidth: screenWidth,
                onTap: () => context.push('/leave/approval'),
                badgeCount: home.pendingLeaveCount,
              ),
              _MenuItem(
                icon: Icons.person_add,
                label: 'Tambah\nKaryawan',
                color: Colors.greenAccent,
                screenWidth: screenWidth,
                onTap: () => context.push('/register-user'),
              ),
            ],
            _MenuItem(icon: Icons.format_list_bulleted, label: 'Permintaan\nTugas', color: Colors.grey.shade300, screenWidth: screenWidth),
            _MenuItem(icon: Icons.add_alert, label: 'Berita', color: Colors.blue, screenWidth: screenWidth, onTap: () => context.push('/announcement')),
            _MenuItem(icon: Icons.download, label: 'Downloads', color: Colors.blueGrey, screenWidth: screenWidth, onTap: () => context.push('/settings/downloaded')),
            _MenuItem(icon: Icons.more_horiz, label: 'Permintaan\nLainnya', color:Colors.grey.shade300, screenWidth: screenWidth),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.screenWidth,
    this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double screenWidth;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _MenuGrid._crossAxisCount(screenWidth);
    final itemWidth = (screenWidth - 32) / crossAxisCount;
    final iconSize = itemWidth * 0.48;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: iconSize * 0.55),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount! > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: itemWidth * 0.9,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: itemWidth > 90 ? 13 : 12, height: 1.2, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.index,
    required this.isExpanded,
    required this.isLiveEmployeeSection,
    required this.workingUsersCount,
    required this.onToggle,
    required this.workingUsersBuilder,
  });

  final String title;
  final String index;
  final bool isExpanded;
  final bool isLiveEmployeeSection;
  final int workingUsersCount;
  final ValueChanged<String> onToggle;
  final Widget Function() workingUsersBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggle(index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  if (isLiveEmployeeSection && workingUsersCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: Text('$workingUsersCount',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: isExpanded
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isLiveEmployeeSection
                  ? workingUsersBuilder()
                  : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Dummy Item 1'), Text('Dummy Item 2')],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WorkingUsersList extends StatelessWidget {
  const _WorkingUsersList({required this.workingUsers});

  final List<Map<String, dynamic>> workingUsers;

  @override
  Widget build(BuildContext context) {
    if (workingUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Tidak ada karyawan saat ini', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: workingUsers.map((user) {
        final photoUrl = user['photoUrl'];
        final hasPhoto = photoUrl != null && photoUrl.toString().isNotEmpty;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: hasPhoto ? NetworkImage(AppConfig.photoUrl(photoUrl)) : null,
            child: hasPhoto ? null : const Icon(Icons.person),
          ),
          title: Text(user['username'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(user['role'] ?? '-'),
          trailing: const Text('Sedang bekerja', style: TextStyle(color: Colors.green)),
        );
      }).toList(),
    );
  }
}

class _PengumumanSection extends StatelessWidget {
  const _PengumumanSection({required this.controller});

  final AnnouncementController controller;

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} pukul ${date.toLocal().hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Berita', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: controller.loadingPreview ? null : controller.loadPreview,
                      child: controller.loadingPreview
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ),
                TextButton(onPressed: () => context.push('/announcement'), child: const Text('Lihat semua')),
              ],
            ),
            if (controller.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Text('Belum dibaca: ${controller.unreadCount}',
                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            if (controller.previewItems.isEmpty && !controller.loadingPreview)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada pengumuman', style: TextStyle(color: Colors.grey)),
              )
            else
              ...controller.previewItems.map((a) => _AnnouncementTile(item: a, formatDate: _formatDate)),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item, required this.formatDate});

  final Announcement item;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/announcement/${item.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              )
            else
              const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(formatDate(item.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('oleh ${item.createdByName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}