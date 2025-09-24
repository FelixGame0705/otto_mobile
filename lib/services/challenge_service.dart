import 'dart:convert';
import 'package:ottobit/models/challenge_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  final HttpService _httpService = HttpService();

  Future<ChallengeApiResponse> getChallenges({
    String? searchTerm,
    String? courseId,
    required String lessonId,
    int? difficultyFrom,
    int? difficultyTo,
    bool includeDeleted = false,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        //'IncludeDeleted': includeDeleted.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };

      if (courseId != null && courseId.isNotEmpty) {
        queryParams['CourseId'] = courseId;
      }
      // if (searchTerm != null && searchTerm.isNotEmpty) {
      //   queryParams['SearchTerm'] = searchTerm;
      // }
      // if (difficultyFrom != null) {
      //   queryParams['DifficultyFrom'] = difficultyFrom.toString();
      // }
      // if (difficultyTo != null) {
      //   queryParams['DifficultyTo'] = difficultyTo.toString();
      // }

      print(
        'ChallengeService: Making request to /v1/challenges/lesson/$lessonId',
      );
      print('ChallengeService: Query params: $queryParams');

      final response = await _httpService.get(
        '/v1/challenges/lesson/$lessonId',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('ChallengeService: Response status: ${response.statusCode}');
      print('ChallengeService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('ChallengeService: Parsed JSON: $jsonData');
        return ChallengeApiResponse.fromJson(jsonData);
      } else {
        print(
          'ChallengeService: Error response: ${response.statusCode} - ${response.body}',
        );
        // Parse to friendly error; handle CHA_009 specifically
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load challenges: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('ChallengeService: Exception: $e');
      rethrow;
    }
  }

  Future<Challenge> getChallengeDetail(String challengeId) async {
    try {
      final path = '/v1/challenges/$challengeId';
      print('ChallengeService: Making request to $path');
      final response = await _httpService.get(path, throwOnError: false);
      print('ChallengeService: Detail status: ${response.statusCode}');
      print('ChallengeService: Detail body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> data =
            (jsonData['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        return Challenge.fromJson(data);
      }
      // Friendly error handling for detail using centralized mapper
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to load challenge: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      print('ChallengeService: Detail exception: $e');
      rethrow;
    }
  }
}
