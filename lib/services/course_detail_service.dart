import 'dart:convert';
import 'package:otto_mobile/models/course_detail_model.dart';
import 'package:otto_mobile/services/http_service.dart';

class CourseDetailService {
  static final CourseDetailService _instance = CourseDetailService._internal();
  factory CourseDetailService() => _instance;
  CourseDetailService._internal();

  final HttpService _httpService = HttpService();

  /// Get course detail by ID
  Future<CourseDetailApiResponse> getCourseDetail(String courseId) async {
    try {
      print('CourseDetailService: Making request to /v1/courses/$courseId');
      
      final response = await _httpService.get('/v1/courses/$courseId');

      print('CourseDetailService: Response status: ${response.statusCode}');
      print('CourseDetailService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('CourseDetailService: Parsed JSON: $jsonData');
        return CourseDetailApiResponse.fromJson(jsonData);
      } else {
        print('CourseDetailService: Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load course detail: ${response.statusCode}');
      }
    } catch (e) {
      print('CourseDetailService: Exception: $e');
      throw Exception('Error fetching course detail: $e');
    }
  }
}
