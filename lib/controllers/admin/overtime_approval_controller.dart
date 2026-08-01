import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/overtime_model.dart';
import '../../services/api.dart';

enum OvertimeDateRange { all, sixMonths, oneYear }

extension OvertimeDateRangeX on OvertimeDateRange {
  String get apiValue {
    switch (this) {
      case OvertimeDateRange.sixMonths:
        return '6m';
      case OvertimeDateRange.oneYear:
        return '1y';
      case OvertimeDateRange.all:
        return 'all';
    }
  }

  String get label {
    switch (this) {
      case OvertimeDateRange.sixMonths:
        return '6 Bulan';
      case OvertimeDateRange.oneYear:
        return '1 Tahun';
      case OvertimeDateRange.all:
        return 'Semua';
    }
  }
}

class OvertimeApprovalController extends ChangeNotifier {
  static const int _limit = 10;

  List<OvertimeModel> pending = [];
  List<OvertimeModel> history = [];

  bool isLoadingPending = false;
  bool isLoadingHistory = false;
  bool isLoadingMorePending = false;
  bool isLoadingMoreHistory = false;
  bool hasMorePending = true;
  bool hasMoreHistory = true;

  int _pagePending = 1;
  int _pageHistory = 1;

  String search = '';
  OvertimeDateRange dateRange = OvertimeDateRange.all;

  Timer? _debounce;

  Future<void> init() async {
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

  void setDateRange(OvertimeDateRange value) {
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
      final res = await DioClient.dio.get('/admin/overtime/pending', queryParameters: _query(1));
      pending = (res.data['data'] as List).map((e) => OvertimeModel.fromJson(e)).toList();
      hasMorePending = res.data['hasMore'] == true;
      _pagePending = 1;
    } catch (e) {
      debugPrint('fetchPending error: $e');
    } finally {
      isLoadingPending = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePending() async {
    if (isLoadingMorePending || !hasMorePending) return;
    isLoadingMorePending = true;
    notifyListeners();
    try {
      final nextPage = _pagePending + 1;
      final res = await DioClient.dio.get('/admin/overtime/pending', queryParameters: _query(nextPage));
      final list = (res.data['data'] as List).map((e) => OvertimeModel.fromJson(e)).toList();
      pending.addAll(list);
      hasMorePending = res.data['hasMore'] == true;
      _pagePending = nextPage;
    } catch (e) {
      debugPrint('loadMorePending error: $e');
    } finally {
      isLoadingMorePending = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/admin/overtime/history', queryParameters: _query(1));
      history = (res.data['data'] as List).map((e) => OvertimeModel.fromJson(e)).toList();
      hasMoreHistory = res.data['hasMore'] == true;
      _pageHistory = 1;
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory() async {
    if (isLoadingMoreHistory || !hasMoreHistory) return;
    isLoadingMoreHistory = true;
    notifyListeners();
    try {
      final nextPage = _pageHistory + 1;
      final res = await DioClient.dio.get('/admin/overtime/history', queryParameters: _query(nextPage));
      final list = (res.data['data'] as List).map((e) => OvertimeModel.fromJson(e)).toList();
      history.addAll(list);
      hasMoreHistory = res.data['hasMore'] == true;
      _pageHistory = nextPage;
    } catch (e) {
      debugPrint('loadMoreHistory error: $e');
    } finally {
      isLoadingMoreHistory = false;
      notifyListeners();
    }
  }

  Future<bool> approve(int overtimeId, {String? note}) async {
    try {
      await DioClient.dio.patch('/admin/overtime/$overtimeId/approve', data: {'note': note});
      await refreshAll();
      return true;
    } catch (e) {
      debugPrint('approve error: $e');
      return false;
    }
  }

  Future<bool> reject(int overtimeId, {String? note}) async {
    try {
      await DioClient.dio.patch('/admin/overtime/$overtimeId/reject', data: {'note': note});
      await refreshAll();
      return true;
    } catch (e) {
      debugPrint('reject error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}