import 'dart:convert';
import 'package:otto_mobile/models/enrollment_model.dart';
import 'package:otto_mobile/services/http_service.dart';
import 'package:otto_mobile/utils/api_error_handler.dart';

class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._internal();
  factory EnrollmentService() => _instance;
  EnrollmentService._internal();

  final HttpService _http = HttpService();

  Future<EnrollmentApiResponse> enroll({required String courseId}) async {
    final body = <String, dynamic>{'courseId': courseId};
    final res = await _http.post(
      '/v1/enrollments',
      body: body,
      throwOnError: false,
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return EnrollmentApiResponse.fromJson(jsonData);
    }
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to enroll: ${res.statusCode}',
    );
    throw Exception(friendly);
  }

  Future<EnrollmentListResponse> getMyEnrollments({
    int pageNumber = 1,
    int pageSize = 10,
    bool? isCompleted,
  }) async {
    final params = <String, String>{
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (isCompleted != null) 'IsCompleted': isCompleted.toString(),
    };
    final res = await _http.get(
      '/v1/enrollments/my-enrollments',
      queryParams: params,
      throwOnError: false,
    );
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return EnrollmentListResponse.fromJson(jsonData);
    }
    
    // Handle specific 400 error for student not found
    if (res.statusCode == 400) {
      final responseBody = res.body.toLowerCase();
      if (responseBody.contains('student not found')) {
        throw Exception('Bạn chưa là học sinh, vui lòng đăng ký.');
      }
    }
    
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to fetch enrollments: ${res.statusCode}',
    );
    throw Exception(friendly);
  }
}


