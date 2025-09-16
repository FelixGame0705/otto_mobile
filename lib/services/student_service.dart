import 'dart:convert';
import 'package:otto_mobile/models/student_model.dart';
import 'package:otto_mobile/services/http_service.dart';

class StudentService {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal();

  final HttpService _http = HttpService();

  Future<StudentApiResponse> getStudentByUser() async {
    final res = await _http.get('/v1/students/by-user');
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return StudentApiResponse.fromJson(jsonData);
    }
    throw Exception('Failed to fetch student: ${res.statusCode}');
  }

  Future<StudentApiResponse> createStudent({
    required String fullname,
    required DateTime dateOfBirth,
  }) async {
    final body = <String, dynamic>{
      'fullname': fullname,
      'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
    };

    final res = await _http.post('/v1/students', body: body);

    if (res.statusCode == 201 || res.statusCode == 200) {
      final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
      return StudentApiResponse.fromJson(jsonData);
    }

    throw Exception('Failed to create student: ${res.statusCode}');
  }
}


