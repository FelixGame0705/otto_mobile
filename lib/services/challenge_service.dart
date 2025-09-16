import 'dart:convert';
import 'package:otto_mobile/models/challenge_model.dart';
import 'package:otto_mobile/services/http_service.dart';

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
        'IncludeDeleted': includeDeleted.toString(),
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
        'LessonId': lessonId,
      };

      if (courseId != null && courseId.isNotEmpty) {
        queryParams['CourseId'] = courseId;
      }
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }
      if (difficultyFrom != null) {
        queryParams['DifficultyFrom'] = difficultyFrom.toString();
      }
      if (difficultyTo != null) {
        queryParams['DifficultyTo'] = difficultyTo.toString();
      }

      print('ChallengeService: Making request to /v1/challenges');
      print('ChallengeService: Query params: $queryParams');

      final response = await _httpService.get('/v1/challenges', queryParams: queryParams);

      print('ChallengeService: Response status: ${response.statusCode}');
      print('ChallengeService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('ChallengeService: Parsed JSON: $jsonData');
        return ChallengeApiResponse.fromJson(jsonData);
      } else {
        print('ChallengeService: Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load challenges: ${response.statusCode}');
      }
    } catch (e) {
      print('ChallengeService: Exception: $e');
      throw Exception('Error fetching challenges: $e');
    }
  }
}


