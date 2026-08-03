import 'api.dart';

class AttendanceApi {
  static Future<Map<String, dynamic>> getPresent({
    String search = '',
    required int page,
    required int limit,
    String? date, // yyyy-MM-dd
  }) async {
    final response = await DioClient.dio.get('/attendance/present', queryParameters: {
      'search': search,
      'page': page,
      'limit': limit,
      if (date != null) 'date': date,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> getAbsent({
    String search = '',
    required int page,
    required int limit,
    String? date,
  }) async {
    final response = await DioClient.dio.get('/attendance/absent', queryParameters: {
      'search': search,
      'page': page,
      'limit': limit,
      if (date != null) 'date': date,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> getCalendar({
    required int year,
    required int month,
  }) async {
    final response = await DioClient.dio.get('/attendance/calendar', queryParameters: {
      'year': year,
      'month': month,
    });
    return response.data;
  }
}