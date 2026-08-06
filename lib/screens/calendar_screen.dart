import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/app_config.dart';
import '../config/routes.dart';
import '../controllers/calendar_controller.dart';
import '../models/calendar_model.dart';
import '../services/auth/auth_service.dart';
import '../widgets/app_scaffold.dart';

const _kStatusColors = {
  DayStatus.holiday: Color(0xFFEF4444),
  DayStatus.leave: Color(0xFF3B82F6),
  DayStatus.both: Color(0xFF8B5CF6),
};

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarController()..init(),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _presentScrollController = ScrollController();
  final ScrollController _absentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); //length -> jumlah tab
    _presentScrollController.addListener(() => _onScroll(_presentScrollController, false));
    _absentScrollController.addListener(() => _onScroll(_absentScrollController, true));
  }

  void _onScroll(ScrollController controller, bool isAbsent) {
    final calendar = context.read<CalendarController>();
    if (calendar.selectedLimit != null) return;
    if (controller.position.pixels >= controller.position.maxScrollExtent - 100) {
      isAbsent ? calendar.loadMoreAbsent() : calendar.loadMorePresent();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _presentScrollController.dispose();
    _absentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Logo_LGradient.png',
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text('Kalender Kehadiran'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Kalender'),
            Tab(icon: Icon(Icons.assignment_ind), text: 'Kelola Cuti'),
            // Tab(icon: Icon(Icons.access_time), text: 'Jadwal Lembur'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CalendarTab(
            searchController: _searchController,
            presentScrollController: _presentScrollController,
            absentScrollController: _absentScrollController,
          ),
          const _LeaveApplicationTab(),
          // const _OvertimeTab(),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab({
    required this.searchController,
    required this.presentScrollController,
    required this.absentScrollController,
  });

  final TextEditingController searchController;
  final ScrollController presentScrollController;
  final ScrollController absentScrollController;

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarController>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthCalendarCard(calendar: calendar),
          const _Legend(),
          const SizedBox(height: 8),
          _SectionCard(
            title: 'Jadwal Bulan Ini — ${DateFormat('MMMM yyyy').format(calendar.focusedDay)}',
            child: calendar.isLoadingMonth
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                : _MonthScheduleList(monthDays: calendar.monthDays),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Status Karyawan - ${DateFormat('dd MMMM yyyy').format(calendar.selectedDay ?? DateTime.now())}',
            child: _StatusKaryawan(
              searchController: searchController,
              presentScrollController: presentScrollController,
              absentScrollController: absentScrollController,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({required this.calendar});

  final CalendarController calendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TableCalendar(
        locale: Localizations.localeOf(context).toString(),
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: calendar.focusedDay,
        rowHeight: 52, // ruang buat dot di bawah angka
        selectedDayPredicate: (day) => isSameDay(calendar.selectedDay, day),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
        ),
        onDaySelected: calendar.selectDay,
        onPageChanged: calendar.changeFocusedMonth,
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _DayCell(day: day, status: calendar.getDayStatus(day)),
          todayBuilder: (context, day, focusedDay) =>
              _DayCell(day: day, status: calendar.getDayStatus(day), isToday: true),
          selectedBuilder: (context, day, focusedDay) =>
              _DayCell(day: day, status: calendar.getDayStatus(day), isSelected: true),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.status, this.isToday = false, this.isSelected = false});

  final DateTime day;
  final DayStatus? status;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = status != null ? _kStatusColors[status] : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : isToday
                ? Theme.of(context).primaryColor.withOpacity(0.12)
                : null,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              color: isSelected
                  ? Colors.white
                  : isToday
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 7,
          child: color != null ? Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)) : null,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  Widget _dot(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        children: [
          _dot(_kStatusColors[DayStatus.holiday]!, 'Libur'),
          _dot(_kStatusColors[DayStatus.leave]!, 'Ada Cuti/Izin'),
          _dot(_kStatusColors[DayStatus.both]!, 'Libur + Cuti'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MonthScheduleList extends StatelessWidget {
  const _MonthScheduleList({required this.monthDays});

  final Map<String, DayInfo> monthDays;

  @override
  Widget build(BuildContext context) {
    final entries = monthDays.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final items = <Widget>[];
    for (final e in entries) {
      final date = DateTime.parse(e.key);
      if (e.value.holiday != null) {
        final h = e.value.holiday!;
        items.add(_ScheduleTile(
          date: date,
          color: h.isCancelled ? Colors.grey : _kStatusColors[DayStatus.holiday]!,
          label: h.isCancelled ? 'DIBATALKAN' : 'LIBUR',
          title: h.reason,
          strikethrough: h.isCancelled,
        ));
      }
      for (final l in e.value.leaves) {
        items.add(_ScheduleTile(
          date: date,
          color: _kStatusColors[DayStatus.leave]!,
          label: l.status,
          title: '${l.reason}',
        ));
      }
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Text('Tidak ada jadwal khusus bulan ini', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(children: items);
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.date,
    required this.color,
    required this.label,
    required this.title,
    this.strikethrough = false,
  });

  final DateTime date;
  final Color color;
  final String label;
  final String title;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8F9FB),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.event, color: Colors.white, size: 18)),
        title: Text(
          DateFormat('dd MMMM yyyy').format(date),
          style: TextStyle(decoration: strikethrough ? TextDecoration.lineThrough : null),
        ),
        subtitle: Text(title, style: TextStyle(decoration: strikethrough ? TextDecoration.lineThrough : null)),
        trailing: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class _StatusKaryawan extends StatelessWidget {
  const _StatusKaryawan({
    required this.searchController,
    required this.presentScrollController,
    required this.absentScrollController,
  });

  final TextEditingController searchController;
  final ScrollController presentScrollController;
  final ScrollController absentScrollController;

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau role...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onChanged: calendar.updateSearch,
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<int?>(
              value: calendar.selectedLimit,
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 15, child: Text('15')),
                DropdownMenuItem(value: 20, child: Text('20')),
              ],
              onChanged: calendar.updateLimit,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (calendar.isFutureDate)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Belum ada data untuk tanggal ini (masih akan datang).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          )
        else ...[
          const Text('Karyawan Hadir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 8),
          _EmployeeSection(
            employees: calendar.presentEmployeesToday,
            accentColor: Colors.green,
            isLoading: calendar.isLoadingPresent,
            currentPage: calendar.presentPage,
            totalPages: calendar.presentTotalPages,
            selectedLimit: calendar.selectedLimit,
            scrollController: presentScrollController,
            onPageChanged: calendar.goToPresentPage,
          ),
          const SizedBox(height: 30),
          const Text('Karyawan Tidak Hadir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          _EmployeeSection(
            employees: calendar.absentEmployeesToday,
            accentColor: Colors.red,
            isLoading: calendar.isLoadingAbsent,
            currentPage: calendar.absentPage,
            totalPages: calendar.absentTotalPages,
            selectedLimit: calendar.selectedLimit,
            scrollController: absentScrollController,
            onPageChanged: calendar.goToAbsentPage,
          ),
        ],
      ],
    );
  }
}

class _EmployeeSection extends StatelessWidget {
  const _EmployeeSection({
    required this.employees,
    required this.accentColor,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.selectedLimit,
    required this.scrollController,
    required this.onPageChanged,
  });

  final List<Employee> employees;
  final Color accentColor;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int? selectedLimit;
  final ScrollController scrollController;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty && !isLoading) {
      return const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text('Tidak ada data', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        ListView.builder(
          controller: selectedLimit == null ? scrollController : null,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final emp = employees[index];
            final hasPhoto = emp.photoUrl != null && emp.photoUrl!.isNotEmpty;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.1),
                  backgroundImage: hasPhoto ? NetworkImage(AppConfig.photoUrl(emp.photoUrl)) : null,
                  child: hasPhoto
                      ? null
                      : Text(emp.username.isNotEmpty ? emp.username[0].toUpperCase() : '?',
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(emp.username),
                subtitle: Text(emp.role),
              ),
            );
          },
        ),
        if (isLoading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()),
        if (selectedLimit != null && totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                ),
                ...List.generate(totalPages, (i) => i + 1).map((p) => GestureDetector(
                  onTap: () => onPageChanged(p),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p == currentPage ? accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$p', style: TextStyle(color: p == currentPage ? Colors.white : Colors.black)),
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LeaveApplicationTab extends StatelessWidget {
  const _LeaveApplicationTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isApprover = auth.role != null && auth.role != 'user';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_ind, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            isApprover ? 'Kelola pengajuan cuti tim kamu' : 'Ajukan cuti atau izin di sini',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.leave),
            icon: const Icon(Icons.event_note),
            label: const Text('Pengajuan Cuti Saya'),
          ),
          if (isApprover) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.leaveApproval),
              icon: const Icon(Icons.fact_check),
              label: const Text('Approve Pengajuan Tim'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OvertimeTab extends StatelessWidget {
  const _OvertimeTab();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Coming Soon'));
}