import 'dart:convert';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonProcessService {
  static final LessonProcessService _instance = LessonProcessService._internal();
  factory LessonProcessService() => _instance;
  LessonProcessService._internal();

  final HttpService _http = HttpService();

  Future<Map<String, dynamic>> getMyProgress({int pageNumber = 1, int pageSize = 10, String? courseId}) async {
    final params = <String, String>{
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (courseId != null && courseId.isNotEmpty) 'CourseId': courseId,
    };
    final res = await _http.get(
      '/v1/lesson-process/my-progress',
      queryParams: params,
      throwOnError: false,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to fetch lesson progress: ${res.statusCode}',
    );
    throw Exception(friendly);
  }
}


