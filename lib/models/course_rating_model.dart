class CourseRating {
  final String id;
  final String courseId;
  final String studentId;
  final int stars;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseRating({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.stars,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseRating.fromJson(Map<String, dynamic> json) {
    return CourseRating(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      studentId: json['studentId'] ?? '',
      stars: json['stars'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'studentId': studentId,
      'stars': stars,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CourseRatingListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<CourseRating> items;

  CourseRatingListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory CourseRatingListResponse.fromJson(Map<String, dynamic> json) {
    return CourseRatingListResponse(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CourseRating.fromJson(item as Map<String, dynamic>))
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

class CourseRatingApiResponse {
  final String message;
  final CourseRatingListResponse? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  CourseRatingApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory CourseRatingApiResponse.fromJson(Map<String, dynamic> json) {
    return CourseRatingApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? CourseRatingListResponse.fromJson(json['data']) : null,
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

class CourseRatingSingleApiResponse {
  final String message;
  final CourseRating? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  CourseRatingSingleApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory CourseRatingSingleApiResponse.fromJson(Map<String, dynamic> json) {
    return CourseRatingSingleApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? CourseRating.fromJson(json['data']) : null,
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

class CreateRatingRequest {
  final int stars;
  final String comment;

  CreateRatingRequest({
    required this.stars,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'stars': stars,
      'comment': comment,
    };
  }
}

class UpdateRatingRequest {
  final int stars;
  final String comment;

  UpdateRatingRequest({
    required this.stars,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'stars': stars,
      'comment': comment,
    };
  }
}
