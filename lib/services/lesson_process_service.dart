import 'dart:convert';
import 'package:ottobit/services/http_service.dart';

class LessonProcessService {
  static final LessonProcessService _instance = LessonProcessService._internal();
  factory LessonProcessService() => _instance;
  LessonProcessService._internal();

  final HttpService _http = HttpService();

  Future<Map<String, dynamic>> getMyProgress({int pageNumber = 1, int pageSize = 10}) async {
    final res = await _http.get(
      '/v1/lesson-process/my-progress',
      queryParams: {
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      },
      throwOnError: false,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch lesson progress: ${res.statusCode}');
  }
}


