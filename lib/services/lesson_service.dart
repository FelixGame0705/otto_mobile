import 'dart:convert';
import 'package:ottobit/models/lesson_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final HttpService _httpService = HttpService();

  Future<LessonApiResponse> getLessons({
    String? searchTerm,
    required String courseId,
    int? durationFrom,
    int? durationTo,
    bool includeDeleted = false,
    int pageNumber = 1,
    int pageSize = 10,
    int sortBy = 1,
    int sortDirection = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'IncludeDeleted': includeDeleted.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
        'CourseId': courseId,
        // Sorting
        'SortBy': sortBy.toString(),
        'SortDirection': sortDirection.toString(),
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }
      if (durationFrom != null) {
        queryParams['DurationFrom'] = durationFrom.toString();
      }
      if (durationTo != null) {
        queryParams['DurationTo'] = durationTo.toString();
      }

      print('LessonService: Making request to /v1/lessons/preview');
      print('LessonService: Query params: $queryParams');

      final response = await _httpService.get(
        '/v1/lessons/preview',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('LessonService: Response status: ${response.statusCode}');
      print('LessonService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('LessonService: Parsed JSON: $jsonData');
        return LessonApiResponse.fromJson(jsonData);
      } else {
        print(
          'LessonService: Error response: ${response.statusCode} - ${response.body}',
        );
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load lessons: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('LessonService error (getLessons): $friendly');
      throw Exception(friendly);
    }
  }

  Future<LessonApiResponse> getLessonById(String lessonId) async {
    try {
      print('LessonService: Making request to /v1/lessons/$lessonId');
      final response = await _httpService.get(
        '/v1/lessons/$lessonId',
        throwOnError: false,
      );

      print('LessonService: Response status: ${response.statusCode}');
      print('LessonService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('LessonService: Parsed JSON: $jsonData');
        return LessonApiResponse.fromJson(jsonData);
      } else {
        print(
          'LessonService: Error response: ${response.statusCode} - ${response.body}',
        );
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load lesson: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('LessonService error (getLessonById): $friendly');
      throw Exception(friendly);
    }
  }
}
