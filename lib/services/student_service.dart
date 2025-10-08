import 'dart:convert';
import 'package:ottobit/models/student_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class StudentService {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal();

  final HttpService _http = HttpService();

  Future<StudentApiResponse> getStudentByUser() async {
    final res = await _http.get('/v1/students/by-user', throwOnError: false);
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return StudentApiResponse.fromJson(jsonData);
    }
    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to fetch student: ${res.statusCode}',
    );
    throw Exception(friendly);
  }

  Future<StudentApiResponse> createStudent({
    required String fullname,
    required String phoneNumber,
    required String address,
    required String state,
    required String city,
    required DateTime dateOfBirth,
  }) async {
    final body = <String, dynamic>{
      'fullname': fullname,
      'phoneNumber': phoneNumber,
      'address': address,
      'state': state,
      'city': city,
      'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
    };

    final res = await _http.post(
      '/v1/students',
      body: body,
      throwOnError: false,
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return StudentApiResponse.fromJson(jsonData);
    }

    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to create student: ${res.statusCode}',
    );
    throw Exception(friendly);
  }

  Future<StudentApiResponse> updateStudent({
    required String studentId,
    required String fullname,
    required String phoneNumber,
    required String address,
    required String state,
    required String city,
    required DateTime dateOfBirth,
  }) async {
    final body = <String, dynamic>{
      'fullname': fullname,
      'phoneNumber': phoneNumber,
      'address': address,
      'state': state,
      'city': city,
      'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
    };

    final res = await _http.put(
      '/v1/students/$studentId',
      body: body,
      throwOnError: false,
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return StudentApiResponse.fromJson(jsonData);
    }

    final friendly = ApiErrorMapper.fromBody(
      res.body,
      statusCode: res.statusCode,
      fallback: 'Failed to update student: ${res.statusCode}',
    );
    throw Exception(friendly);
  }
}


