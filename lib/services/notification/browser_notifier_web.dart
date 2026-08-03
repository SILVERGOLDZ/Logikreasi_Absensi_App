import 'dart:html' as html;

class BrowserNotifier {
  static Future<void> requestPermission() async {
    if (!html.Notification.supported) return;
    await html.Notification.requestPermission();
  }

  /// Menampilkan notifikasi browser. `imageUrl` dipakai langsung sebagai
  /// icon — browser yang fetch, TIDAK ada file yang didownload/disimpan
  /// ke storage lokal.
  static void show({
    required String title,
    String? body,
    String? imageUrl,
    String? type,
  }) {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != "granted") return;

    final notif = html.Notification(title, body: body, icon: imageUrl);

    notif.onClick.listen((_) {
      notif.close();
      if (type != null) {
        html.window.dispatchEvent(html.CustomEvent("app-notification-click", detail: type));
      }
    });
  }

  /// Dengarkan klik notifikasi, baik dari:
  /// - notifikasi foreground (dilempar via CustomEvent di atas)
  /// - notifikasi background (dilempar dari service worker via postMessage)
  static void listenForClicks(void Function(String type) onType) {
    html.window.addEventListener("app-notification-click", (event) {
      final detail = (event as html.CustomEvent).detail;
      if (detail is String) onType(detail);
    });

    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map && data["type"] == "notification-click") {
        final payload = data["payload"];
        if (payload is String) onType(payload);
      }
    });
  }
}