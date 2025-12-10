import 'dart:convert';
import 'package:ottobit/models/enrollment_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

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
    String? courseId,
  }) async {
    final params = <String, String>{
      'PageNumber': pageNumber.toString(),
      'PageSize': pageSize.toString(),
      if (isCompleted != null) 'IsCompleted': isCompleted.toString(),
      if (courseId != null && courseId.isNotEmpty) 'CourseId': courseId,
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
        final friendly = ApiErrorMapper.fromBody(
          res.body,
          statusCode: res.statusCode,
          fallback: 'Bạn chưa là học sinh, vui lòng đăng ký.',
        );
        throw Exception(friendly);
      }
    }
    
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to fetch enrollments: ${res.statusCode}',
    );
    throw Exception(friendly);
  }

  Future<bool> isEnrolledInCourse({required String courseId}) async {
    try {
      final response = await getMyEnrollments(
        pageNumber: 1,
        pageSize: 1,
        courseId: courseId,
      );
      return response.items.any((e) => e.courseId == courseId);
    } catch (e) {
      rethrow;
    }
  }
}


