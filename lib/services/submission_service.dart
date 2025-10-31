import 'dart:convert';
import 'package:ottobit/models/submission_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class SubmissionService {
  static final SubmissionService _instance = SubmissionService._internal();
  factory SubmissionService() => _instance;
  SubmissionService._internal();

  final HttpService _http = HttpService();

  Future<SubmissionApiResponse> createSubmission({
    required String challengeId,
    required String codeJson,
    required int star,
  }) async {
    final body = CreateSubmissionRequest(
      challengeId: challengeId,
      codeJson: codeJson,
      star: star,
    ).toJson();
    
    print('📤 Submitting challenge: $challengeId with $star stars');
    print('📤 Code JSON: $codeJson');
    print('📤 Request body: $body');
    
    final res = await _http.post(
      '/v1/submissions',
      body: body,
      throwOnError: false,
    );
    print('📥 Response status: ${res.statusCode}');
    print('📥 Response body: ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return SubmissionApiResponse.fromJson(jsonData);
    }
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to create submission: ${res.statusCode}',
    );
    throw Exception(friendly);
  }

  Future<SubmissionListApiResponse> getBestSubmissionsByLesson({
    required String lessonId,
  }) async {
    final params = <String, String>{
      'LessonId': lessonId,
    };
    final res = await _http.get(
      '/v1/submissions/best',
      queryParams: params,
      throwOnError: false,
    );
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return SubmissionListApiResponse.fromJson(jsonData);
    }
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to fetch best submissions: ${res.statusCode}',
    );
    throw Exception(friendly);
  }

  Future<SubmissionPage> getMySubmissions({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
    };
    final res = await _http.get(
      '/v1/submissions/my-submissions',
      queryParams: params,
      throwOnError: false,
    );
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (jsonData['data'] as Map<String, dynamic>?);
      if (data != null) {
        return SubmissionPage.fromJson(data);
      }
      return const SubmissionPage(size: 0, page: 1, total: 0, totalPages: 1, items: []);
    }
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to fetch my submissions: ${res.statusCode}',
    );
    throw Exception(friendly);
  }
}
