import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../services/api.dart';
import '../services/socket_service.dart';

class AnnouncementController extends ChangeNotifier {
  AnnouncementController() {
    _newAnnouncementSub = SocketService.instance.on('newAnnouncement').listen((data) {
      if (data == null) return;
      _handleNewAnnouncement(Announcement.fromJson(Map<String, dynamic>.from(data)));
    });
  }

  int? _currentUserId;

  final Map<int, Announcement> _byId = {};

  List<int> _previewOrder = [];
  List<int> _listOrder = [];

  int unreadCount = 0;

  bool loadingPreview = false;
  bool loadingList = false;
  bool hasMoreList = true;

  int _listPage = 1;
  static const int _listLimit = 10;

  StreamSubscription? _newAnnouncementSub;

  List<Announcement> get previewItems =>
      _previewOrder.map((id) => _byId[id]).whereType<Announcement>().toList();

  List<Announcement> get listItems =>
      _listOrder.map((id) => _byId[id]).whereType<Announcement>().toList();

  /// Dipanggil dari ProxyProvider setiap kali AuthService berubah.
  /// Hanya reset & reload kalau user-nya benar-benar berganti (login/logout/switch),
  /// bukan setiap kali AuthService.notifyListeners() terpanggil karena alasan lain.
  void updateUser(int? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _reset();
    if (userId != null) {
      init();
    }
  }

  void _reset() {
    _byId.clear();
    _previewOrder = [];
    _listOrder = [];
    unreadCount = 0;
    loadingPreview = false;
    loadingList = false;
    hasMoreList = true;
    _listPage = 1;
    notifyListeners();
  }

  Future<void> init() async {
    await Future.wait([loadPreview(), loadUnreadCount()]);
  }

  Future<void> loadUnreadCount() async {
    try {
      final res = await DioClient.dio.get('/announcement/unread-count');
      unreadCount = res.data['unreadCount'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal load unread count: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await DioClient.dio.post('/announcement/mark-all-read');
      _byId.updateAll((_, item) => item.copyWith(isRead: true));
      unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal menandai semua pengumuman sebagai dibaca: $e');
    }
  }

  Future<void> loadPreview() async {
    loadingPreview = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/announcement', queryParameters: {'page': 1, 'limit': 3});
      final data = (res.data['data'] as List).map((e) => Announcement.fromJson(e)).toList();
      for (final item in data) {
        _byId[item.id] = item;
      }
      _previewOrder = data.map((e) => e.id).toList();
    } catch (e) {
      debugPrint('Gagal load preview pengumuman: $e');
    } finally {
      loadingPreview = false;
      notifyListeners();
    }
  }

  /// Panggil sekali saat ListPengumumanScreen dibuka (reset ke halaman 1).
  Future<void> loadListInitial() async {
    _listPage = 1;
    hasMoreList = true;
    _listOrder = [];
    await loadListMore();
  }

  Future<void> refreshList() => loadListInitial();

  Future<void> loadListMore() async {
    if (loadingList || !hasMoreList) return;
    loadingList = true;
    notifyListeners();
    try {
      final res =
      await DioClient.dio.get('/announcement', queryParameters: {'page': _listPage, 'limit': _listLimit});
      final data = (res.data['data'] as List).map((e) => Announcement.fromJson(e)).toList();
      for (final item in data) {
        _byId[item.id] = item;
      }
      _listOrder = [..._listOrder, ...data.map((e) => e.id)];
      hasMoreList = res.data['hasMore'] ?? false;
      _listPage += 1;
    } catch (e) {
      debugPrint('Gagal load pengumuman: $e');
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  /// GET detail otomatis menandai terbaca di backend. Method ini
  /// menyinkronkan hasilnya ke cache lokal — inilah yang membuat Home
  /// & List ikut ter-update begitu detail dibuka, dari screen manapun.
  Future<Announcement> loadDetail(int id) async {
    final res = await DioClient.dio.get('/announcement/$id');
    final detail = Announcement.fromJson({...res.data, 'isRead': true});
    _applyServerRead(detail);
    return detail;
  }

  void _applyServerRead(Announcement detail) {
    final wasUnread = _byId[detail.id]?.isRead == false;
    _byId[detail.id] = detail;
    if (wasUnread && unreadCount > 0) unreadCount -= 1;
    notifyListeners();
  }

  void _handleNewAnnouncement(Announcement item) {
    _byId[item.id] = item;
    _previewOrder = [item.id, ..._previewOrder.take(2)];
    unreadCount += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _newAnnouncementSub?.cancel();
    super.dispose();
  }
}