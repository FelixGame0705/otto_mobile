class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final int progress;
  final DateTime enrollmentDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String studentName;
  final String courseTitle;
  final String courseDescription;
  final String courseImageUrl;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.progress,
    required this.enrollmentDate,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.studentName,
    required this.courseTitle,
    required this.courseDescription,
    required this.courseImageUrl,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      courseId: json['courseId'] ?? '',
      progress: json['progress'] ?? 0,
      enrollmentDate: DateTime.parse(json['enrollmentDate']),
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      studentName: json['studentName'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      courseImageUrl: json['courseImageUrl'] ?? '',
    );
  }
}

class EnrollmentApiResponse {
  final String message;
  final Enrollment? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  EnrollmentApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory EnrollmentApiResponse.fromJson(Map<String, dynamic> json) {
    return EnrollmentApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? Enrollment.fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class EnrollmentListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Enrollment> items;

  EnrollmentListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory EnrollmentListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
        .toList();
    return EnrollmentListResponse(
      size: data['size'] ?? 0,
      page: data['page'] ?? 1,
      total: data['total'] ?? 0,
      totalPages: data['totalPages'] ?? 1,
      items: items,
    );
  }
}


