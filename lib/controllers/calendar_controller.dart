import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/calendar_model.dart';
import '../services/attendance_api.dart';
import '../services/socket_service.dart';

/// Status of a day, used by the screen to decide which dot color to show.
enum DayStatus { holiday, leave, both }

class CalendarController extends ChangeNotifier {
  CalendarController() {
    _selectedDay = DateTime.now();
    _subscribeToSocket();
  }

  // ---- Calendar / month state ----
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, DayInfo> monthDays = {};
  bool isLoadingMonth = false;

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;

  // ---- Search & pagination ----
  String searchQuery = '';
  int? selectedLimit = 10;
  static const int allModeBatchSize = 20;

  int presentPage = 1;
  int absentPage = 1;
  int presentTotalPages = 1;
  int absentTotalPages = 1;

  List<Employee> presentEmployeesToday = [];
  List<Employee> absentEmployeesToday = [];

  bool isLoadingPresent = false;
  bool isLoadingAbsent = false;
  bool isFutureDate = false;

  StreamSubscription? _attendanceSub;
  StreamSubscription? _calendarSub;

  String get todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  void _subscribeToSocket() {
    _attendanceSub = SocketService.instance.on('attendanceChanged').listen((data) {
      if (data == null) return;
      fetchDayStatus(_selectedDay ?? DateTime.now());
    });

    _calendarSub = SocketService.instance.on('calendarChanged').listen((_) {
      fetchMonthData(_focusedDay);
    });
  }

  /// Call once from the screen (e.g. via ChangeNotifierProvider's create).
  Future<void> init() async {
    await fetchMonthData(_focusedDay);
    await fetchDayStatus(_selectedDay!);
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
    fetchDayStatus(selectedDay);
  }

  void changeFocusedMonth(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
    fetchMonthData(focusedDay);
  }

  void updateSearch(String value) {
    searchQuery = value;
    notifyListeners();
    if (!isFutureDate) {
      final key = dateKey(_selectedDay ?? DateTime.now());
      fetchPresent(reset: true, date: key);
      fetchAbsent(reset: true, date: key);
    }
  }

  void updateLimit(int? value) {
    selectedLimit = value;
    notifyListeners();
    if (!isFutureDate) {
      final key = dateKey(_selectedDay ?? DateTime.now());
      fetchPresent(reset: true, date: key);
      fetchAbsent(reset: true, date: key);
    }
  }

  Future<void> fetchMonthData(DateTime month) async {
    isLoadingMonth = true;
    notifyListeners();
    try {
      final result = await AttendanceApi.getCalendar(year: month.year, month: month.month);
      final rawDays = (result['days'] as Map<String, dynamic>? ?? {});
      monthDays = rawDays.map((k, v) => MapEntry(k, DayInfo.fromJson(v)));
    } catch (e) {
      debugPrint('Gagal load kalender bulan: $e');
    } finally {
      isLoadingMonth = false;
      notifyListeners();
    }
  }

  Future<void> fetchDayStatus(DateTime day) async {
    final key = dateKey(day);
    isFutureDate = key.compareTo(todayStr) > 0;

    if (isFutureDate) {
      presentEmployeesToday = [];
      absentEmployeesToday = [];
      notifyListeners();
      return;
    }

    notifyListeners();
    await fetchPresent(reset: true, date: key);
    await fetchAbsent(reset: true, date: key);
  }

  Future<void> fetchPresent({bool reset = false, String? date}) async {
    final targetDate = date ?? dateKey(_selectedDay ?? DateTime.now());
    if (reset) {
      presentPage = 1;
      presentEmployeesToday = [];
    }
    isLoadingPresent = true;
    notifyListeners();
    try {
      final limit = selectedLimit ?? allModeBatchSize;
      final result = await AttendanceApi.getPresent(
        search: searchQuery,
        page: presentPage,
        limit: limit,
        date: targetDate,
      );
      final newData = (result['data'] as List).map((e) => Employee.fromJson(e)).toList();
      presentEmployeesToday =
      (selectedLimit == null && !reset) ? [...presentEmployeesToday, ...newData] : newData;
      presentTotalPages = result['totalPages'] ?? 1;
    } catch (e) {
      debugPrint('Gagal load present: $e');
    } finally {
      isLoadingPresent = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePresent() async {
    if (isLoadingPresent || presentPage >= presentTotalPages) return;
    presentPage++;
    await fetchPresent(date: dateKey(_selectedDay ?? DateTime.now()));
  }

  Future<void> goToPresentPage(int page) async {
    presentPage = page;
    await fetchPresent(date: dateKey(_selectedDay ?? DateTime.now()));
  }

  Future<void> fetchAbsent({bool reset = false, String? date}) async {
    final targetDate = date ?? dateKey(_selectedDay ?? DateTime.now());
    if (reset) {
      absentPage = 1;
      absentEmployeesToday = [];
    }
    isLoadingAbsent = true;
    notifyListeners();
    try {
      final limit = selectedLimit ?? allModeBatchSize;
      final result = await AttendanceApi.getAbsent(
        search: searchQuery,
        page: absentPage,
        limit: limit,
        date: targetDate,
      );
      final newData = (result['data'] as List).map((e) => Employee.fromJson(e)).toList();
      absentEmployeesToday =
      (selectedLimit == null && !reset) ? [...absentEmployeesToday, ...newData] : newData;
      absentTotalPages = result['totalPages'] ?? 1;
    } catch (e) {
      debugPrint('Gagal load absent: $e');
    } finally {
      isLoadingAbsent = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreAbsent() async {
    if (isLoadingAbsent || absentPage >= absentTotalPages) return;
    absentPage++;
    await fetchAbsent(date: dateKey(_selectedDay ?? DateTime.now()));
  }

  Future<void> goToAbsentPage(int page) async {
    absentPage = page;
    await fetchAbsent(date: dateKey(_selectedDay ?? DateTime.now()));
  }

  /// Business logic only — no Color/Flutter UI types here on purpose.
  /// The screen maps this to whatever color it wants to draw.
  DayStatus? getDayStatus(DateTime day) {
    final info = monthDays[dateKey(day)];
    if (info == null) return null;
    final hasHoliday = info.holiday != null && !info.holiday!.isCancelled;
    final hasLeave = info.leaves.isNotEmpty;
    if (hasHoliday && hasLeave) return DayStatus.both;
    if (hasHoliday) return DayStatus.holiday;
    if (hasLeave) return DayStatus.leave;
    return null;
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _calendarSub?.cancel();
    super.dispose();
  }
}