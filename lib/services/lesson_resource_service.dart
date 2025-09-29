import 'dart:convert';

import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonResourceService {
  static final LessonResourceService _instance = LessonResourceService._internal();
  factory LessonResourceService() => _instance;
  LessonResourceService._internal();

  final HttpService _http = HttpService();

  Future<LessonResourceApiResponse> getLessonResources({
    required String lessonId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _http.get(
        '/v1/lesson-resources/lesson/$lessonId',
        queryParams: {
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
        },
        throwOnError: false,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonResourceApiResponse.fromJson(jsonData);
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể tải tài nguyên bài học (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }

  Future<LessonResourceItem> getLessonResourceById(String resourceId) async {
    try {
      final response = await _http.get(
        '/v1/lesson-resources/$resourceId',
        throwOnError: false,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return LessonResourceItem.fromJson(data);
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể tải chi tiết tài nguyên (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }
}


