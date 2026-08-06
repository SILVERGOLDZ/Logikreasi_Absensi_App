import 'package:absensi_app/config/app_config.dart';
import 'package:absensi_app/services/auth/auth_service.dart';
import 'package:absensi_app/widgets/no_internet_dialog.dart';
import 'package:dio/dio.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  static void init(AuthService auth) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (auth.token != null) {
            options.headers["Authorization"] = "Bearer ${auth.token}";
          }
          handler.next(options);
        },
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) {
          if (_isConnectionError(error)) {
            showNoInternetDialog();
          }
          handler.next(error);
        },
      ),
    );
  }

  static bool _isConnectionError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      default:
        return false;
    }
  }
}