import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../controllers/admin/leave_approval_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/leave_status_card.dart';

class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeaveApprovalController()..init(),
      child: const _LeaveApprovalBody(),
    );
  }
}

class _LeaveApprovalBody extends StatefulWidget {
  const _LeaveApprovalBody();

  @override
  State<_LeaveApprovalBody> createState() => _LeaveApprovalBodyState();
}

class _LeaveApprovalBodyState extends State<_LeaveApprovalBody> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LeaveApprovalController>();

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Cuti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Pengajuan Saya',
            onPressed: () => context.push(AppRoutes.leave),
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
                final leave = controller.pending[i];
                return LeaveStatusCard(
                  leave: leave,
                  onTap: () => context.push(
                    AppRoutes.leaveDetail,
                    extra: {
                      'leave': leave,
                      'canApprove': true,
                      'onApprove': (String? note) => controller.approve(leave.id, note: note),
                      'onReject': (String? note) => controller.reject(leave.id, note: note),
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
                final leave = controller.history[i];
                return LeaveStatusCard(
                  leave: leave,
                  onTap: () => context.push(AppRoutes.leaveDetail, extra: {'leave': leave}),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}