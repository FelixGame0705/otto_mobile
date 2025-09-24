import 'dart:convert';
import 'package:ottobit/models/course_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final HttpService _httpService = HttpService();

  /// Get courses with pagination and search
  Future<CourseApiResponse> getCourses({
    String? searchTerm,
    bool includeDeleted = false,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'IncludeDeleted': includeDeleted.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }

      print('CourseService: Making request to /v1/courses');
      print('CourseService: Query params: $queryParams');
      
      final response = await _httpService.get(
        '/v1/courses',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('CourseService: Response status: ${response.statusCode}');
      print('CourseService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('CourseService: Parsed JSON: $jsonData');
        return CourseApiResponse.fromJson(jsonData);
      } else {
        print('CourseService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load courses: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CourseService: Exception: $e');
      throw Exception('Error fetching courses: $e');
    }
  }

  /// Get a specific course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final response = await _httpService.get('/v1/courses/$courseId');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonData['data'] != null) {
          return Course.fromJson(jsonData['data']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching course: $e');
    }
  }

  /// Enroll in a course
  Future<bool> enrollInCourse(String courseId) async {
    try {
      final response = await _httpService.post(
        '/v1/courses/$courseId/enroll',
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error enrolling in course: $e');
    }
  }

  /// Unenroll from a course
  Future<bool> unenrollFromCourse(String courseId) async {
    try {
      final response = await _httpService.delete(
        '/v1/courses/$courseId/enroll',
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error unenrolling from course: $e');
    }
  }

  /// Check if user is enrolled in a course
  Future<bool> isEnrolledInCourse(String courseId) async {
    try {
      final response = await _httpService.get(
        '/v1/courses/$courseId/enrollment-status',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonData['isEnrolled'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
