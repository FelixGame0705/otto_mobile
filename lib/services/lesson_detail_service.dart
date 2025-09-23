import 'dart:convert';
import 'package:otto_mobile/models/lesson_detail_model.dart';
import 'package:otto_mobile/services/http_service.dart';

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
      throw Exception('Không thể bắt đầu học (mã ${res.statusCode}).');
    } catch (e) {
      final raw = e.toString();
      print('LessonDetailService: startLesson exception: $raw');
      throw Exception(raw.replaceFirst('Exception: ', ''));
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
        // Try to extract server-provided message/errorCode for better UX
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final message = (jsonData['message'] as String?)?.trim();
          final errorCode = (jsonData['errorCode'] as String?)?.trim();
          if (errorCode == 'USER_003') {
            // Business rule: previous lessons must be completed first
            throw Exception(
              'Bạn cần hoàn thành các bài học trước đó trước khi xem bài này.',
            );
          }
          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        } catch (_) {}
        throw Exception('Failed to load lesson detail: ${response.statusCode}');
      }
    } catch (e) {
      print('LessonDetailService: Exception: $e');
      throw Exception('Error fetching lesson detail: $e');
    }
  }
}
