import 'api.dart';

class HolidayApi {
  static Future<Map<String, dynamic>> create({
    required String startDate, // yyyy-MM-dd
    String? endDate,           // yyyy-MM-dd, opsional
    required String reason,
    required String title,
    required String content,
  }) async {
    final response = await DioClient.dio.post('/admin/holiday', data: {
      'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'reason': reason,
      'title': title,
      'content': content,
    });
    return response.data;
  }

  static Future<void> cancel(int id) async {
    await DioClient.dio.patch('/admin/holiday/$id/cancel');
  }

  static Future<List<dynamic>> list({int? year, int? month}) async {
    final response = await DioClient.dio.get('/admin/holiday', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return response.data as List<dynamic>;
  }
}