import 'dart:convert';
import 'package:otto_mobile/models/lesson_detail_model.dart';
import 'package:otto_mobile/services/http_service.dart';

class LessonDetailService {
  static final LessonDetailService _instance = LessonDetailService._internal();
  factory LessonDetailService() => _instance;
  LessonDetailService._internal();

  final HttpService _httpService = HttpService();

  Future<LessonDetailApiResponse> getLessonDetail(String lessonId) async {
    try {
      print('LessonDetailService: Making request to /v1/lessons/$lessonId');
      final response = await _httpService.get('/v1/lessons/$lessonId');

      print('LessonDetailService: Response status: ${response.statusCode}');
      print('LessonDetailService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('LessonDetailService: Parsed JSON: $jsonData');
        return LessonDetailApiResponse.fromJson(jsonData);
      } else {
        print('LessonDetailService: Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load lesson detail: ${response.statusCode}');
      }
    } catch (e) {
      print('LessonDetailService: Exception: $e');
      throw Exception('Error fetching lesson detail: $e');
    }
  }
}
