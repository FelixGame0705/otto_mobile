class Student {
  final String id;
  final String userId;
  final String fullname;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int enrollmentsCount;
  final int submissionsCount;

  Student({
    required this.id,
    required this.userId,
    required this.fullname,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    required this.enrollmentsCount,
    required this.submissionsCount,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullname: json['fullname'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      enrollmentsCount: json['enrollmentsCount'] ?? 0,
      submissionsCount: json['submissionsCount'] ?? 0,
    );
  }
}

class StudentApiResponse {
  final String message;
  final Student? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  StudentApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory StudentApiResponse.fromJson(Map<String, dynamic> json) {
    return StudentApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? Student.fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}


