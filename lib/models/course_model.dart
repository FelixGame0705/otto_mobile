class Course {
  final String id;
  final String createdById;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int lessonsCount;
  final int enrollmentsCount;
  final String createdByName;

  Course({
    required this.id,
    required this.createdById,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.lessonsCount,
    required this.enrollmentsCount,
    required this.createdByName,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      createdById: json['createdById'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      lessonsCount: json['lessonsCount'] ?? 0,
      enrollmentsCount: json['enrollmentsCount'] ?? 0,
      createdByName: json['createdByName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdById': createdById,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lessonsCount': lessonsCount,
      'enrollmentsCount': enrollmentsCount,
      'createdByName': createdByName,
    };
  }
}

class CourseListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Course> items;

  CourseListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory CourseListResponse.fromJson(Map<String, dynamic> json) {
    return CourseListResponse(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'page': page,
      'total': total,
      'totalPages': totalPages,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CourseApiResponse {
  final String message;
  final CourseListResponse? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  CourseApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory CourseApiResponse.fromJson(Map<String, dynamic> json) {
    return CourseApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? CourseListResponse.fromJson(json['data']) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp,
    };
  }
}
