import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/leave_model.dart';
import '../../services/api.dart';
import '../../services/socket_service.dart';

enum LeaveDateRange { all, sixMonths, oneYear }

extension LeaveDateRangeX on LeaveDateRange {
  String get apiValue {
    switch (this) {
      case LeaveDateRange.sixMonths:
        return '6m';
      case LeaveDateRange.oneYear:
        return '1y';
      case LeaveDateRange.all:
        return 'all';
    }
  }

  String get label {
    switch (this) {
      case LeaveDateRange.sixMonths:
        return '6 Bulan';
      case LeaveDateRange.oneYear:
        return '1 Tahun';
      case LeaveDateRange.all:
        return 'Semua';
    }
  }
}

class LeaveApprovalController extends ChangeNotifier {
  static const int _limit = 10;

  List<LeaveModel> pending = [];
  List<LeaveModel> history = [];

  bool isLoadingPending = false;
  bool isLoadingHistory = false;
  bool isLoadingMorePending = false;
  bool isLoadingMoreHistory = false;
  bool hasMorePending = true;
  bool hasMoreHistory = true;

  int _pagePending = 1;
  int _pageHistory = 1;

  String search = '';
  LeaveDateRange dateRange = LeaveDateRange.all;

  Timer? _debounce;
  StreamSubscription? _socketSub;

  Future<void> init() async {
    _socketSub = SocketService.instance.on('leaveStatusChanged').listen((_) {
      refreshAll();
    });
    await refreshAll();
  }

  Future<void> refreshAll() async {
    _pagePending = 1;
    _pageHistory = 1;
    hasMorePending = true;
    hasMoreHistory = true;
    await Future.wait([fetchPending(), fetchHistory()]);
  }

  void setSearch(String value) {
    search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), refreshAll);
  }

  void setDateRange(LeaveDateRange value) {
    if (dateRange == value) return;
    dateRange = value;
    refreshAll();
  }

  Map<String, dynamic> _query(int page) => {
    'page': page,
    'limit': _limit,
    if (search.isNotEmpty) 'search': search,
    'dateRange': dateRange.apiValue,
  };

  Future<void> fetchPending() async {
    isLoadingPending = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/leave/pending', queryParameters: _query(1));
      pending = (res.data['data'] as List).map((e) => LeaveModel.fromJson(e)).toList();
      hasMorePending = res.data['hasMore'] == true;
      _pagePending = 1;
    } catch (e) {
      debugPrint('fetchPending error: $e');
    }
    isLoadingPending = false;
    notifyListeners();
  }

  Future<void> loadMorePending() async {
    if (isLoadingMorePending || !hasMorePending) return;
    isLoadingMorePending = true;
    notifyListeners();
    try {
      final nextPage = _pagePending + 1;
      final res = await DioClient.dio.get('/admin/leave/pending', queryParameters: _query(nextPage));
      final list = (res.data['data'] as List).map((e) => LeaveModel.fromJson(e)).toList();
      pending.addAll(list);
      hasMorePending = res.data['hasMore'] == true;
      _pagePending = nextPage;
    } catch (e) {
      debugPrint('loadMorePending error: $e');
    }
    isLoadingMorePending = false;
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/leave/history', queryParameters: _query(1));
      history = (res.data['data'] as List).map((e) => LeaveModel.fromJson(e)).toList();
      hasMoreHistory = res.data['hasMore'] == true;
      _pageHistory = 1;
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> loadMoreHistory() async {
    if (isLoadingMoreHistory || !hasMoreHistory) return;
    isLoadingMoreHistory = true;
    notifyListeners();
    try {
      final nextPage = _pageHistory + 1;
      final res = await DioClient.dio.get('/admin/leave/history', queryParameters: _query(nextPage));
      final list = (res.data['data'] as List).map((e) => LeaveModel.fromJson(e)).toList();
      history.addAll(list);
      hasMoreHistory = res.data['hasMore'] == true;
      _pageHistory = nextPage;
    } catch (e) {
      debugPrint('loadMoreHistory error: $e');
    }
    isLoadingMoreHistory = false;
    notifyListeners();
  }

  Future<bool> approve(int leaveId, {String? note}) async {
    try {
      await DioClient.dio.post('/admin/leave/$leaveId/approve', data: {'note': note});
      await refreshAll();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reject(int leaveId, {String? note}) async {
    try {
      await DioClient.dio.post('/admin/leave/$leaveId/reject', data: {'note': note});
      await refreshAll();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _socketSub?.cancel();
    super.dispose();
  }
}