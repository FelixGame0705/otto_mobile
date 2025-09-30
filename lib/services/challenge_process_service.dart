import 'dart:convert';
import 'package:ottobit/models/challenge_process_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class ChallengeProcessService {
  static final ChallengeProcessService _instance = ChallengeProcessService._internal();
  factory ChallengeProcessService() => _instance;
  ChallengeProcessService._internal();

  final HttpService _httpService = HttpService();

  Future<ChallengeProcessApiResponse> getMyChallenges({
    required String lessonId,
    String? courseId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'LessonId': lessonId,
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };

      if (courseId != null && courseId.isNotEmpty) {
        queryParams['CourseId'] = courseId;
      }

      print(
        'ChallengeProcessService: Making request to /v1/challenge-process/my-challenges',
      );
      print('ChallengeProcessService: Query params: $queryParams');

      final response = await _httpService.get(
        '/v1/challenge-process/my-challenges',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('ChallengeProcessService: Response status: ${response.statusCode}');
      print('ChallengeProcessService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('ChallengeProcessService: Parsed JSON: $jsonData');
        return ChallengeProcessApiResponse.fromJson(jsonData);
      } else {
        print(
          'ChallengeProcessService: Error response: ${response.statusCode} - ${response.body}',
        );
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load challenge processes: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('ChallengeProcessService: Exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyChallengesByCourse({
    required String courseId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'CourseId': courseId,
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };
    final response = await _httpService.get(
      '/v1/challenge-process/my-challenges',
      queryParams: queryParams,
      throwOnError: false,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load challenge processes by course: ${response.statusCode}');
  }
}
