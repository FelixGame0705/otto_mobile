import 'dart:convert';
import 'package:otto_mobile/models/submission_model.dart';
import 'package:otto_mobile/services/http_service.dart';

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
    
    final res = await _http.post('/v1/submissions', body: body);
    print('📥 Response status: ${res.statusCode}');
    print('📥 Response body: ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return SubmissionApiResponse.fromJson(jsonData);
    }
    throw Exception('Failed to create submission: ${res.statusCode} - ${res.body}');
  }
}
