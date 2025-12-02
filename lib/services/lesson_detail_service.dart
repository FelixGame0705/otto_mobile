import 'dart:convert';
import 'package:ottobit/models/lesson_detail_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonDetailService {
  static final LessonDetailService _instance = LessonDetailService._internal();
  factory LessonDetailService() => _instance;
  LessonDetailService._internal();

  final HttpService _httpService = HttpService();

  Future<String> startLesson(String lessonId) async {
    try {
      final endpoint = '/v1/lesson-process/start-lesson/$lessonId';
      print('LessonDetailService: Starting lesson via POST $endpoint');
      final res = await _httpService.post(endpoint);
      print('LessonDetailService: Start lesson status: ${res.statusCode}');
      print('LessonDetailService: Start lesson body: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
          final msg = (jsonData['message'] as String?)?.trim();
          return msg?.isNotEmpty == true ? msg! : 'Bắt đầu học thành công';
        } catch (_) {
          return 'Bắt đầu học thành công';
        }
      }
      final friendly = ApiErrorMapper.fromBody(
        res.body,
        statusCode: res.statusCode,
        fallback: 'Không thể bắt đầu học (mã ${res.statusCode}).',
      );
      throw Exception(friendly);
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('LessonDetailService error (startLesson): $friendly');
      throw Exception(friendly);
    }
  }

  Future<LessonDetailApiResponse> getLessonDetail(String lessonId) async {
    try {
      print('LessonDetailService: Making request to /v1/lessons/$lessonId');
      // Allow reading business error payloads (e.g., prerequisites not met)
      final response = await _httpService.get(
        '/v1/lessons/$lessonId',
        throwOnError: false,
      );

      print('LessonDetailService: Response status: ${response.statusCode}');
      print('LessonDetailService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('LessonDetailService: Parsed JSON: $jsonData');
        return LessonDetailApiResponse.fromJson(jsonData);
      } else {
        print(
          'LessonDetailService: Error response: ${response.statusCode} - ${response.body}',
        );
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load lesson detail: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('LessonDetailService error (getLessonDetail): $friendly');
      throw Exception(friendly);
    }
  }
}
