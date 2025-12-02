import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ottobit/models/course_robot_model.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CourseRobotService {
  static const String _baseUrl = 'https://ottobit-be.felixtien.dev/api/v1';
  
  Future<CourseRobotResponse> getCourseRobots({
    int page = 1,
    int size = 50,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$_baseUrl/course-robots?Page=$page&Size=$size');
      
      final response = await http.get(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseRobotResponse.fromJson(jsonData);
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load course robots: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      // Log thân thiện, tránh lộ Exception thô
      print('CourseRobotService error (getCourseRobots): $friendly');
      throw Exception(friendly);
    }
  }

  Future<CourseRobot?> getCourseRobotByCourseId(String courseId) async {
    try {
      final response = await getCourseRobots();
      if (response.data != null) {
        for (final robot in response.data!.items) {
          if (robot.courseId == courseId) {
            return robot;
          }
        }
      }
      return null;
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('CourseRobotService error (getCourseRobotByCourseId): $friendly');
      throw Exception(friendly);
    }
  }
}
