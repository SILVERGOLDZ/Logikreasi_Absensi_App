import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
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
  final _pendingScroll = ScrollController();
  final _historyScroll = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pendingScroll.addListener(_onPendingScroll);
    _historyScroll.addListener(_onHistoryScroll);
  }

  void _onPendingScroll() {
    if (_pendingScroll.position.pixels >= _pendingScroll.position.maxScrollExtent - 200) {
      context.read<OvertimeApprovalController>().loadMorePending();
    }
  }

  void _onHistoryScroll() {
    if (_historyScroll.position.pixels >= _historyScroll.position.maxScrollExtent - 200) {
      context.read<OvertimeApprovalController>().loadMoreHistory();
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _pendingScroll.dispose();
    _historyScroll.dispose();
    _searchCtrl.dispose();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nama pegawai...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) => controller.setSearch(v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<OvertimeDateRange>(
                  value: controller.dateRange,
                  underline: const SizedBox(),
                  items: OvertimeDateRange.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setDateRange(v);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                RefreshIndicator(
                  onRefresh: controller.fetchPending,
                  child: controller.pending.isEmpty
                      ? ListView(children: const [
                    Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tidak ada pengajuan pending', style: TextStyle(color: Colors.grey)))),
                  ])
                      : ListView.builder(
                    controller: _pendingScroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.pending.length + (controller.hasMorePending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= controller.pending.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
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
                    controller: _historyScroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.history.length + (controller.hasMoreHistory ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= controller.history.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
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
          ),
        ],
      ),
    );
  }
}