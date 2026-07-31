// screens/overtime/overtime_screen.dart
//
// Mirror pola LeaveScreen.
// TODO: tambahkan AppRoutes.overtime, AppRoutes.overtimeCreate,
// AppRoutes.overtimeDetail ke config/routes.dart kamu (nama route
// di bawah ini masih placeholder string).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart'; // TODO: sesuaikan
import '../../../controllers/overtime_controller.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/overtime_status_card.dart';

class OvertimeScreen extends StatelessWidget {
  const OvertimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OvertimeController()..init(),
      child: const _OvertimeScreenBody(),
    );
  }
}

class _OvertimeScreenBody extends StatelessWidget {
  const _OvertimeScreenBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OvertimeController>();

    return AppScaffold(
      appBar: AppBar(title: const Text('Pengajuan Lembur Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>(AppRoutes.overtimeCreate);
          if (result == true) controller.fetchMyOvertimes();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
      body: controller.isLoadingOvertimes
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: controller.fetchMyOvertimes,
        child: controller.myOvertimes.isEmpty
            ? ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada pengajuan lembur', style: TextStyle(color: Colors.grey))),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myOvertimes.length,
          itemBuilder: (context, i) {
            final overtime = controller.myOvertimes[i];
            return OvertimeStatusCard(
              overtime: overtime,
              onTap: () => context.push(AppRoutes.overtimeDetail, extra: {'overtime': overtime}),
            );
          },
        ),
      ),
    );
  }
}