class AppConfig {
  // Ganti IP/port cukup di sini
  static const String host = "192.168.99.43";
  static const int port = 3001;

  static const String baseUrl = "http://$host:$port/api";
  static const String socketUrl = "http://$host:$port";

  static String photoUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    return "http://$host:$port$path";
  }
}