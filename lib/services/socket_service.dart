import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/app_config.dart';

/// Single socket connection for the whole app.
///
/// Call [connect] once, at app start (see main.dart). Any screen/controller
/// can then subscribe to a given event with [on] without worrying about
/// creating duplicate connections or double-registering listeners:
///
/// ```dart
/// _sub = SocketService.instance.on('attendanceChanged').listen((data) { ... });
/// ...
/// _sub.cancel(); // in dispose()
/// ```
class SocketService {
  SocketService._internal();

  static final SocketService instance = SocketService._internal();

  IO.Socket? _socket;
  final Map<String, StreamController<dynamic>> _controllers = {};

  bool get isConnected => _socket?.connected ?? false;

  /// Opens the underlying socket connection. Safe to call multiple times;
  /// only connects once.
  void connect() {
    if (_socket != null) return;

    _socket = IO.io(
      AppConfig.socketUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    _socket!.onConnect((_) => debugPrint('SocketService: connected'));
    _socket!.onDisconnect((_) => debugPrint('SocketService: disconnected'));
    _socket!.onConnectError((err) => debugPrint('SocketService: connect error -> $err'));

    // Re-attach any event listeners that were requested before the socket
    // existed (e.g. if a controller subscribed before connect() ran).
    for (final entry in _controllers.entries) {
      _socket!.on(entry.key, (data) => entry.value.add(data));
    }
  }

  /// Returns a broadcast stream of events for [event]. Multiple
  /// screens/controllers can listen independently; `socket.on(event, ...)`
  /// is only ever registered once per event name.
  Stream<dynamic> on(String event) {
    final controller = _controllers.putIfAbsent(event, () {
      final c = StreamController<dynamic>.broadcast();
      _socket?.on(event, (data) => c.add(data));
      return c;
    });
    return controller.stream;
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// Full teardown. Only call this on app shutdown / logout, not per-screen.
  void disconnect() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _socket?.dispose();
    _socket = null;
  }
}