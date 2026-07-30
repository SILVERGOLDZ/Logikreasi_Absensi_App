import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../controllers/leave_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/leave_status_card.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeaveController()..init(),
      child: const _LeaveScreenBody(),
    );
  }
}

class _LeaveScreenBody extends StatelessWidget {
  const _LeaveScreenBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LeaveController>();

    return AppScaffold(
      appBar: AppBar(title: const Text('Pengajuan Cuti Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>(AppRoutes.leaveCreate);
          if (result == true) controller.fetchMyLeaves();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
      body: controller.isLoadingLeaves
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: controller.fetchMyLeaves,
        child: controller.myLeaves.isEmpty
            ? ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada pengajuan cuti', style: TextStyle(color: Colors.grey))),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myLeaves.length,
          itemBuilder: (context, i) {
            final leave = controller.myLeaves[i];
            return LeaveStatusCard(
              leave: leave,
              onTap: () => context.push(AppRoutes.leaveDetail, extra: {'leave': leave}),
            );
          },
        ),
      ),
    );
  }
}