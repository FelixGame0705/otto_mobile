import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      // Debug: In log ngay đầu hàm để đảm bảo không bị miss
      debugPrint('=== LessonService.getLessons() CALLED ===');
      debugPrint('LessonService: searchTerm parameter received: "$searchTerm"');
      debugPrint('LessonService: searchTerm type: ${searchTerm.runtimeType}');
      debugPrint('LessonService: searchTerm == null: ${searchTerm == null}');
      if (searchTerm != null) {
        debugPrint('LessonService: searchTerm.isEmpty: ${searchTerm.isEmpty}');
        debugPrint('LessonService: searchTerm.isNotEmpty: ${searchTerm.isNotEmpty}');
        debugPrint('LessonService: searchTerm.length: ${searchTerm.length}');
        debugPrint('LessonService: searchTerm.trim().isEmpty: ${searchTerm.trim().isEmpty}');
        debugPrint('LessonService: searchTerm.trim().isNotEmpty: ${searchTerm.trim().isNotEmpty}');
      }
      
      final queryParams = <String, String>{
        'IncludeDeleted': includeDeleted.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
        'CourseId': courseId,
        // Sorting
        'SortBy': sortBy.toString(),
        'SortDirection': sortDirection.toString(),
      };

      debugPrint('LessonService: queryParams BEFORE adding SearchTerm: $queryParams');
      debugPrint('LessonService: queryParams keys BEFORE: ${queryParams.keys.toList()}');

      // Thêm SearchTerm vào queryParams nếu có giá trị
      if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        final trimmedSearchTerm = searchTerm.trim();
        queryParams['SearchTerm'] = trimmedSearchTerm;
        debugPrint('LessonService: ✅ SearchTerm ADDED to queryParams: "$trimmedSearchTerm"');
        debugPrint('LessonService: queryParams AFTER adding SearchTerm: $queryParams');
      } else {
        debugPrint('LessonService: ❌ SearchTerm NOT added');
        debugPrint('LessonService:   - searchTerm == null: ${searchTerm == null}');
        if (searchTerm != null) {
          debugPrint('LessonService:   - searchTerm.trim().isEmpty: ${searchTerm.trim().isEmpty}');
        }
      }
      
      if (durationFrom != null) {
        queryParams['DurationFrom'] = durationFrom.toString();
      }
      if (durationTo != null) {
        queryParams['DurationTo'] = durationTo.toString();
      }
      
      debugPrint('LessonService: Final queryParams: $queryParams');
      debugPrint('LessonService: Final queryParams keys: ${queryParams.keys.toList()}');
      debugPrint('LessonService: Final queryParams values: ${queryParams.values.toList()}');
      debugPrint('LessonService: SearchTerm in final queryParams: ${queryParams['SearchTerm']}');
      debugPrint('LessonService: SearchTerm key exists: ${queryParams.containsKey('SearchTerm')}');

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
