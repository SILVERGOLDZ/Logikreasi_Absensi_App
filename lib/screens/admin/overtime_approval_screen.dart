// screens/admin/overtime_approval_screen.dart
//
// Mirror pola LeaveApprovalScreen.
// TODO: tambahkan AppRoutes.overtime & AppRoutes.overtimeDetail
// (dan pastikan route ini terdaftar sebagai halaman admin).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart'; // TODO: sesuaikan
import '../../controllers/admin/overtime_approval_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/overtime_status_card.dart';

class OvertimeApprovalScreen extends StatelessWidget {
  const OvertimeApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OvertimeApprovalController()..init(),
      child: const _OvertimeApprovalBody(),
    );
  }
}

class _OvertimeApprovalBody extends StatefulWidget {
  const _OvertimeApprovalBody();

  @override
  State<_OvertimeApprovalBody> createState() => _OvertimeApprovalBodyState();
}

class _OvertimeApprovalBodyState extends State<_OvertimeApprovalBody> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OvertimeApprovalController>();

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Lembur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Pengajuan Saya',
            onPressed: () => context.push(AppRoutes.overtime),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Pending (${controller.pending.length})'),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          RefreshIndicator(
            onRefresh: controller.fetchPending,
            child: controller.pending.isEmpty
                ? ListView(children: const [
              Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tidak ada pengajuan pending', style: TextStyle(color: Colors.grey)))),
            ])
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.pending.length,
              itemBuilder: (context, i) {
                final overtime = controller.pending[i];
                return OvertimeStatusCard(
                  overtime: overtime,
                  onTap: () => context.push(
                    AppRoutes.overtimeDetail,
                    extra: {
                      'overtime': overtime,
                      'canApprove': true,
                      'onApprove': (String? note) => controller.approve(overtime.id, note: note),
                      'onReject': (String? note) => controller.reject(overtime.id, note: note),
                    },
                  ),
                );
              },
            ),
          ),
          RefreshIndicator(
            onRefresh: controller.fetchHistory,
            child: controller.history.isEmpty
                ? ListView(children: const [
              Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Belum ada riwayat', style: TextStyle(color: Colors.grey)))),
            ])
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.history.length,
              itemBuilder: (context, i) {
                final overtime = controller.history[i];
                return OvertimeStatusCard(
                  overtime: overtime,
                  onTap: () => context.push(AppRoutes.overtimeDetail, extra: {'overtime': overtime}),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}