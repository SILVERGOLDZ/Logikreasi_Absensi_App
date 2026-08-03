/// Stub untuk platform mobile. Method di sini TIDAK PERNAH benar-benar
/// dipanggil di mobile karena semua pemanggilnya sudah digate `kIsWeb`,
/// tapi tetap harus ada supaya kode bisa di-compile untuk semua platform.
class BrowserNotifier {
  static Future<void> requestPermission() async {}

  static void show({
    required String title,
    String? body,
    String? imageUrl,
    String? type,
  }) {}

  static void listenForClicks(void Function(String type) onType) {}
}