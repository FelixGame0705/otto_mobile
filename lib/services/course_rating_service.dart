import 'dart:convert';
import 'package:ottobit/models/course_rating_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CourseRatingService {
  static final CourseRatingService _instance = CourseRatingService._internal();
  factory CourseRatingService() => _instance;
  CourseRatingService._internal();

  final HttpService _httpService = HttpService();

  /// Get course ratings with pagination
  Future<CourseRatingApiResponse> getCourseRatings({
    required String courseId,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      print('CourseRatingService: Making request to /v1/courses/$courseId/ratings');
      print('CourseRatingService: Query params: $queryParams');
      
      final response = await _httpService.get(
        '/v1/courses/$courseId/ratings',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('CourseRatingService: Response status: ${response.statusCode}');
      print('CourseRatingService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('CourseRatingService: Parsed JSON: $jsonData');
        return CourseRatingApiResponse.fromJson(jsonData);
      } else {
        print('CourseRatingService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load course ratings: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CourseRatingService: Exception: $e');
      throw Exception('Error fetching course ratings: $e');
    }
  }

  /// Create a new rating for a course
  Future<CourseRatingSingleApiResponse> createRating({
    required String courseId,
    required int stars,
    required String comment,
  }) async {
    try {
      final request = CreateRatingRequest(
        stars: stars,
        comment: comment,
      );

      print('CourseRatingService: Creating rating for course $courseId');
      print('CourseRatingService: Request data: ${request.toJson()}');
      
      final response = await _httpService.post(
        '/v1/courses/$courseId/ratings',
        body: request.toJson(),
        throwOnError: false,
      );

      print('CourseRatingService: Response status: ${response.statusCode}');
      print('CourseRatingService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('CourseRatingService: Parsed JSON: $jsonData');
        return CourseRatingSingleApiResponse.fromJson(jsonData);
      } else {
        print('CourseRatingService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to create rating: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CourseRatingService: Exception: $e');
      throw Exception('Error creating rating: $e');
    }
  }

  /// Update an existing rating
  Future<CourseRatingSingleApiResponse> updateRating({
    required String courseId,
    required int stars,
    required String comment,
  }) async {
    try {
      final request = UpdateRatingRequest(
        stars: stars,
        comment: comment,
      );

      print('CourseRatingService: Updating rating for course $courseId');
      print('CourseRatingService: Request data: ${request.toJson()}');
      
      final response = await _httpService.put(
        '/v1/courses/$courseId/ratings',
        body: request.toJson(),
        throwOnError: false,
      );

      print('CourseRatingService: Response status: ${response.statusCode}');
      print('CourseRatingService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('CourseRatingService: Parsed JSON: $jsonData');
        return CourseRatingSingleApiResponse.fromJson(jsonData);
      } else {
        print('CourseRatingService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to update rating: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CourseRatingService: Exception: $e');
      throw Exception('Error updating rating: $e');
    }
  }

  /// Delete a rating
  Future<bool> deleteRating({
    required String courseId,
  }) async {
    try {
      print('CourseRatingService: Deleting rating for course $courseId');
      
      final response = await _httpService.delete(
        '/v1/courses/$courseId/ratings',
        throwOnError: false,
      );

      print('CourseRatingService: Response status: ${response.statusCode}');
      print('CourseRatingService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('CourseRatingService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to delete rating: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CourseRatingService: Exception: $e');
      throw Exception('Error deleting rating: $e');
    }
  }

  /// Get current user's rating for a course
  Future<CourseRatingSingleApiResponse> getMyRating({
    required String courseId,
  }) async {
    try {
      print('CourseRatingService: Getting my rating for course $courseId');
      final response = await _httpService.get(
        '/v1/courses/$courseId/ratings/mine',
        throwOnError: false,
      );

      print('CourseRatingService: Response status: ${response.statusCode}');
      print('CourseRatingService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CourseRatingSingleApiResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // No rating yet
        return CourseRatingSingleApiResponse.fromJson({
          'message': 'Not found',
          'data': null,
          'errors': null,
          'errorCode': null,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get my rating: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CourseRatingService: Exception: $e');
      throw Exception('Error fetching my rating: $e');
    }
  }
}
